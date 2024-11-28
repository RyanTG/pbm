class UserSubmission < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :user, optional: true, counter_cache: true
  belongs_to :location, optional: true
  belongs_to :machine, optional: true

  after_commit :update_contributor_rank

  geocoded_by :lat_and_lon, latitude: :lat, longitude: :lon

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  NEW_LMX_TYPE = 'new_lmx'.freeze
  CONTACT_US_TYPE = 'contact_us'.freeze
  NEW_CONDITION_TYPE = 'new_condition'.freeze
  REMOVE_MACHINE_TYPE = 'remove_machine'.freeze
  SUGGEST_LOCATION_TYPE = 'suggest_location'.freeze
  LOCATION_METADATA_TYPE = 'location_metadata'.freeze
  NEW_SCORE_TYPE = 'new_msx'.freeze
  CONFIRM_LOCATION_TYPE = 'confirm_location'.freeze
  DELETE_LOCATION_TYPE = 'delete_location'.freeze
  IC_TOGGLE_TYPE = 'ic_toggle'.freeze
  NEW_PICTURE_TYPE = 'new_picture'.freeze

  def user_email
    user ? user.email : ''
  end

  def lat_and_lon
    [lat, lon].join(', ')
  end

  def update_contributor_rank
    if user
      if user.contributor_rank.blank? && user.user_submissions_count.between?(51, 250)
        user.contributor_rank = 'Super Mapper'
      elsif user.contributor_rank == 'Super Mapper' && user.user_submissions_count&.between?(251, 500)
        user.contributor_rank = 'Legendary Mapper'
      elsif user.contributor_rank == 'Legendary Mapper' && user.user_submissions_count > 500
        user.contributor_rank = 'Grand Champ Mapper'
      end
    end
  end
end
