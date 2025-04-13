class LocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_ipdb_id, :by_opdb_id, :by_machine_id, :by_machine_single_id, :by_machine_name, :by_city_id, :by_state_id, :by_machine_group_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :by_city_name, :by_state_name, :by_city_no_state, :by_center_point_and_ne_boundary, :region, :by_is_stern_army, :by_ic_active, :user_faved, :manufacturer
  before_action :authenticate_user!, except: %i[index show autocomplete autocomplete_city render_machines render_machines_count render_scores render_last_updated render_location_detail render_former_machines render_recent_activity]
  rate_limit to: 50, within: 20.minutes, only: :index, if: lambda { |req| req.is_bot? }

  def is_bot?
    CrawlerDetect.is_crawler?(request.user_agent)
  end

  def create
    @location = Location.new(location_params)
    if @location.save
      redirect_to @location, notice: "Location was successfully created."
    else
      render action: "new"
    end
  end

  def autocomplete
    searchable_locations = @region&.locations || Location.all

    locations =
      searchable_locations
      .where("clean_items(name) ilike '%' || clean_items(?) || '%'", params[:term])
      .sort_by(&:name)
      .map do |l|
        {
          label: "#{l.name} (#{l.city}#{l.state.blank? ? '' : ', '}#{l.state})",
          value: l.name,
          id: l.id
        }
      end

    render json: locations
  end

  def autocomplete_city
    @searchable_cities =
      Location.where("clean_items(city) ilike '%' || clean_items(?) || '%'", params[:term])
              .sort_by(&:city)
              .map do |l|
                {
                  label: l.city_and_state,
                  value: l.city_and_state
                }
              end
    render json: @searchable_cities.uniq
  end

  def index
    @locations = []
    @locations_geojson = []
    @region = Region.find_by_name(params[:region])

    params.delete(:by_location_id) if !params[:by_location_name].blank? && !params[:by_location_id].blank?

    @locations = apply_scopes(Location).select([ "id", "lat", "lon", "machine_count" ])

    @locations_size = @locations.size
    @machines_sum = @locations.sum(&:machine_count)

    @locations_geojson = @locations.sort { |a, b| a.machine_count - b.machine_count }.map.with_index do |location, index|
      {
        type: "Feature",
        id: location.id,
        properties: {
          machine_count: location.machine_count,
          id: location.id,
          order: index
        },
        geometry: {
          type: "Point",
          coordinates: [ location.lon.to_f, location.lat.to_f ]
        }
      }
    end.to_json

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = apply_scopes(Location).includes(:location_type)
    else
      @locations = apply_scopes(Location).select([ "id", "lat", "lon", "name", "location_type_id", "street", "city", "state", "zip", "machine_count" ]).order("locations.name").includes(:location_type).limit(100)
    end

    respond_with(@locations) do |format|
      format.html { render partial: "locations/locations", layout: false }
    end
  end

  def render_machines
    machines = LocationMachineXref.where(location_id: params[:id]).includes(:machine)
    machines = machines.sort { |a, b| a.machine.massaged_name <=> b.machine.massaged_name }
    logged_in = current_user ? "logged_in" : "logged_out"

    render partial: "locations/render_machines", locals: { location_machine_xrefs: machines, logged_in: logged_in }
  end

  def render_machines_count
    render partial: "locations/render_machines_count", locals: { location: Location.find(params[:id]) }
  end

  def render_scores
    render partial: "locations/render_scores", locals: { lmx: LocationMachineXref.find(params[:id]) }
  end

  def render_update_metadata
    render partial: "locations/render_update_metadata", locals: { l: Location.find(params[:id]) }
  end

  def render_last_updated
    render partial: "locations/render_last_updated", locals: { l: Location.find(params[:id]) }
  end

  def render_add_machine
    render partial: "locations/render_add_machine", locals: { l: Location.find(params[:id]) }
  end

  def render_location_detail
    @record_not_found = false
    l = Location.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "locations/render_location_detail", locals: { l: l }
    end
  end

  def render_former_machines
    @record_not_found = false
    l = Location.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "locations/render_former_machines", locals: { l: l }
    end
  end

  def render_recent_activity
    @record_not_found = false
    l = Location.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "locations/render_recent_activity", locals: { l: l }
    end
  end

  def not_found
    @record_not_found = true
  end

  def update_metadata
    l = Location.find(params[:id])

    values, message_type = l.update_metadata(
      current_user.nil? ? nil : current_user,
      phone: params["new_phone_#{l.id}"],
      website: params["new_website_#{l.id}"],
      operator_id: params["new_operator_#{l.id}"],
      location_type_id: params["new_location_type_#{l.id}"],
      description: params["new_desc_#{l.id}"]
    )

    if message_type == "errors"
      render json: { error: values.uniq.join("<br />") }
    else
      render nothing: true
    end
  end

  def confirm
    l = Location.find(params[:id])
    l.confirm(current_user || nil)
    l
  end

  private

  def location_params
    params.require(:location).permit(:name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :zone_id, :region_id, :location_type_id, :description, :operator_id, :date_last_updated, :last_updated_by_user_id, :machine_ids, :is_stern_army, :ic_active)
  end
end
