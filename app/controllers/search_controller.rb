class SearchController < ApplicationController
  LOCATION_LIMIT = 8
  CITY_LIMIT = 5

  def autocomplete
    term = params[:term].to_s
    return render json: [] if term.length < 3

    searchable_locations = @region&.locations || Location.all

    locations = searchable_locations
      .where("clean_items(name) ilike '%' || clean_items(?) || '%'", term)
      .order(:name)
      .limit(LOCATION_LIMIT)
      .map do |l|
        {
          label: "#{l.name} (#{l.city}#{l.state.blank? ? '' : ', '}#{l.state})",
          value: l.name,
          id: l.id,
          type: 'location'
        }
      end

    cities = Location
      .where("clean_items(city) ilike '%' || clean_items(?) || '%'", term)
      .sort_by(&:city)
      .map { |l| { label: l.city_and_state, city: l.city, state: l.state } }
      .uniq { |c| c[:label] }
      .first(CITY_LIMIT)
      .map { |c| c.merge(value: c[:label], type: 'city') }

    render json: locations + cities
  end
end
