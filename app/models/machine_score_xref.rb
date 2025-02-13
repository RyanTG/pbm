class MachineScoreXref < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  belongs_to :user, optional: true
  belongs_to :location_machine_xref, optional: true, counter_cache: true, touch: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref
  strip_attributes

  scope :zone_id, lambda { |id|
    joins(:location_machine_xref).joins(:location).where("
      locations.zone_id = ?
    ", id)
  }

  scope :region, lambda { |name|
    r = Region.find_by_name(name.downcase)
    joins(:location_machine_xref).joins(:location).where("
      location_machine_xrefs.id = machine_score_xrefs.location_machine_xref_id
      and locations.id = location_machine_xrefs.location_id
      and locations.region_id = ?
    ", r.id)
  }

  def username
    user ? user.username : ""
  end

  def create_user_submission
    user_info = user ? user.username : "UNKNOWN USER"
    submission = "#{user_info} added a high score of #{number_with_precision(score, precision: 0, delimiter: ',')} on #{machine.name_and_year} at #{location.name} in #{location.city}"

    UserSubmission.create(user_name: user.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, high_score: score, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: submission, user: user)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
    User.increment_counter(:num_msx_scores_added, user&.id)
  end
end
