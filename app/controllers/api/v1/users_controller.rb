module Api
  module V1
    class UsersController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json
      rate_limit to: 10, within: 10.minutes, only: [ :auth_details, :forgot_password, :resend_confirmation, :signup ]

      api :GET, "/api/v1/users/:id/list_fave_locations.json", "Fetch list of favorite locations"
      description "Fetch list of favorite locations"
      param :id, Integer, desc: "ID of user", required: true
      formats [ "json" ]
      def list_fave_locations
        user = User.find(params[:id])
        locations = user.user_fave_locations.includes([ location: %i[location_type machines] ])

        return_response(
          locations,
          "user_fave_locations",
          [ location: { include: { location_type: {}, machines: { except: %i[is_active created_at updated_at ipdb_link machine_group_id ipdb_id kineticist_url opdb_id opdb_img opdb_img_height opdb_img_width display machine_type machine_display ic_eligible] } },
          except: %i[phone website created_at updated_at zone_id region_id description operator_id is_stern_army country is_active] } ]
        )
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown user", "errors")
      end

      api :GET, "/api/v1/users/total_user_count.json", "Fetch total count of users"
      description "Fetch total count of users"
      formats [ "json" ]
      def total_user_count
        return_response({ total_user_count: User.count }, nil)
      end

      api :POST, "/api/v1/users/:id/add_fave_location.json", "Adds a location to your fave list"
      description "Adds a location to your fave list"
      param :id, Integer, desc: "ID of user", required: true
      param :location_id, Integer, desc: "ID of location to add", required: true
      formats [ "json" ]
      def add_fave_location
        user = User.find(params[:id])
        location = Location.find(params[:location_id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        if UserFaveLocation.where(user: user, location: location).count.positive?
          return_response("This location is already saved as a fave.", "errors")
          return
        end

        UserFaveLocation.create(user: user, location: location)

        return_response("Successfully added fave", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :POST, "/api/v1/users/:id/remove_fave_location.json", "Removes a location from your fave list"
      description "Removes a location from your fave list"
      param :id, Integer, desc: "ID of user", required: true
      param :location_id, Integer, desc: "ID of location to remove", required: true
      formats [ "json" ]
      def remove_fave_location
        user = User.find(params[:id])
        location = Location.find(params[:location_id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        UserFaveLocation.where(user: user, location: location).destroy_all

        return_response("Successfully removed fave", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :GET, "/api/v1/users/auth_details.json", "Fetch auth info for a user"
      description "This info includes the user's API token."
      param :login, String, desc: "User's username or email address", required: true
      param :password, String, desc: "User's password", required: true
      def auth_details
        if params[:login].blank? || params[:password].blank?
          return_response("login and password are required fields", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:login].downcase).first || User.where("lower(email) = ?", params[:login].downcase).first

        unless user
          return_response("Unknown user", "errors")
          return
        end

        unless user.valid_password?(params[:password])
          return_response("Incorrect password", "errors")
          return
        end

        unless user.confirmed_at
          return_response("User is not yet confirmed. Please follow emailed confirmation instructions.", "errors")
          return
        end

        if user.is_disabled
          return_response("Your account is disabled. Please contact us if you think this is a mistake.", "errors")
          return
        end

        return_response(user, "user", [], %i[username email authentication_token])
      end

      api :POST, "/api/v1/users/forgot_password.json", "Password retrieval"
      description "Reset a forgotten password"
      param :identification, String, desc: "A username or email address", required: true
      def forgot_password
        if params[:identification].blank?
          return_response("Please send an email or username to use this feature", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:identification].downcase).first || User.where("lower(email) = ?", params[:identification].downcase).first

        unless user
          return_response("Can not find a user associated with this email or username", "errors")
          return
        end

        user.send_reset_password_instructions
        return_response("Password reset request successful.", "msg")
      end

      api :POST, "/api/v1/users/resend_confirmation.json", "Resend confirmation"
      description "Resend an account confirmation"
      param :identification, String, desc: "A username or email address", required: true
      def resend_confirmation
        if params[:identification].blank?
          return_response("Please send an email or username to use this feature", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:identification].downcase).first || User.where("lower(email) = ?", params[:identification].downcase).first

        unless user
          return_response("Can not find a user associated with this email or username", "errors")
          return
        end

        user.send_confirmation_instructions
        return_response("Confirmation info resent.", "msg")
      end

      api :POST, "/api/v1/users/signup.json", "Signup a new user"
      description "Signup a new user for the PBM"
      param :username, String, desc: "New username", required: true
      param :email, String, desc: "New email address", required: true
      param :password, String, desc: "New password", required: true
      param :confirm_password, String, desc: "New password confirmation", required: true
      def signup
        if params[:password].blank? || params[:confirm_password].blank?
          return_response("password can not be blank", "errors")
          return
        end

        if params[:username].blank? || params[:email].blank?
          return_response("username and email are required fields", "errors")
          return
        end

        if params[:password] != params[:confirm_password]
          return_response("your entered passwords do not match", "errors")
          return
        end

        user = User.find_by_username(params[:username])
        if user
          return_response("This username already exists", "errors")
          return
        end

        user = User.find_by_email(params[:email])
        if user
          return_response("This email address already exists", "errors")
          return
        end

        user = User.new(email: params[:email], password: params[:password], password_confirmation: params[:confirm_password], username: params[:username])
        user.save ? return_response(user, "user", [], %i[username email authentication_token]) : return_response(user.errors.full_messages.join(","), "errors")
      end

      api :GET, "/api/v1/users/:id/profile_info.json", "Fetch profile info for a user"
      param :id, Integer, desc: "ID of user", required: true
      formats [ "json" ]
      def profile_info
        user = User.find(params[:id])

        return_response(
          user,
          "profile_info",
          [],
          %i[admin_rank_int admin_title contributor_rank_int contributor_rank flag num_total_submissions num_machines_added num_machines_removed num_locations_edited num_locations_suggested num_lmx_comments_left num_msx_scores_added profile_list_of_edited_locations profile_list_of_high_scores created_at]
        )
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find user", "errors")
      end

      api :POST, "/api/v1/users/:id/update_user_flag", "Set a country or U.S. flag icon for your user"
      param :id, Integer, desc: "ID of user", required: true
      param :user_flag, String, desc: "ISO code for flag", required: false
      formats [ "json" ]
      def update_user_flag
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        user.flag = params[:user_flag]
        if user.save
          return_response(user, "user", [], %i[flag])
        else
          return_response("Unknown ISO code", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end
    end
  end
end
