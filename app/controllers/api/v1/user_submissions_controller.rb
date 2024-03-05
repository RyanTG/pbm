module Api
  module V1
    class UserSubmissionsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      has_scope :region

      api :GET, '/api/v1/region/:region/user_submissions.json', 'Fetch user submissions for a single region'
      param :region, String, desc: 'Name of the Region you want to see user submissions for', required: true
      def index
        user_submissions = apply_scopes(UserSubmission)
        user_submissions = user_submissions.select { |s| s.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }

        return_response(user_submissions, 'user_submissions')
      end

      api :GET, '/api/v1/user_submissions/location.json', 'Fetch user submissions for a location'
      param :id, Integer, desc: 'ID of location', required: true
      param :submission_type, String, desc: 'Type of submission to filter to', required: false
      formats ['json']
      def location
        location = Location.find(params[:id])

        if params[:submission_type]
          user_submissions = UserSubmission.where(location_id: location, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day, submission_type: params[:submission_type])
        else
          user_submissions = UserSubmission.where(location_id: location, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day)
        end
        sorted_submissions = user_submissions.order('created_at DESC')

        return_response(sorted_submissions, 'user_submissions')
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find location', 'errors')
      end

      api :GET, '/api/v1/user_submissions/total_user_submission_count.json', 'Fetch total count of user submissions'
      description 'Fetch total count of user submissions'
      formats ['json']
      def total_user_submission_count
        return_response({ total_user_submission_count: UserSubmission.count }, nil)
      end

      api :GET, '/api/v1/user_submissions/top_users.json', 'Fetch top 10 users by submission count'
      description 'Fetch top 10 users by submission count'
      formats ['json']
      def top_users
        sid = Arel::Table.new('user_submissions')
        uid = Arel::Table.new('users')
        top_users = UserSubmission.select(
          [
            sid[:user_id], uid[:username], Arel.star.count.as('submission_count')
          ]
        ).joins(
          UserSubmission.arel_table.join(User.arel_table).on(uid[:id].eq(sid[:user_id])).join_sources
        ).order(:submission_count).reverse_order.group(uid[:username], sid[:user_id]).limit(10)

        return_response(top_users, nil)
      end

      MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS = 30

      api :GET, '/api/v1/user_submissions/list_within_range.json', 'Fetch user submissions within N miles of provided lat/lon'
      param :lat, String, desc: 'Latitude', required: true
      param :lon, String, desc: 'Longitude', required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles, max of 250', required: false
      param :min_date_of_submission, String, desc: 'Earliest date to consider updates from, format YYYY-MM-DD', required: false
      param :submission_type, String, desc: 'Type of submission to filter to', required: false
      def list_within_range
        if params[:max_distance].blank?
          max_distance = MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS
        elsif params[:max_distance].to_i > 250
          max_distance = 250
        else
          max_distance = params[:max_distance].to_i
        end
        min_date_of_submission = params[:min_date_of_submission] ? params[:min_date_of_submission].to_date.beginning_of_day : 1.month.ago.beginning_of_day

        user_submissions = nil
        if params[:submission_type]
          user_submissions = UserSubmission.where.not(lat: nil).where(created_at: min_date_of_submission..Date.today.end_of_day, submission_type: params[:submission_type]).near([params[:lat], params[:lon]], max_distance, order: false)
        else
          user_submissions = UserSubmission.where.not(lat: nil).where(created_at: min_date_of_submission..Date.today.end_of_day).near([params[:lat], params[:lon]], max_distance, order: false)
        end

        sorted_submissions = user_submissions.order('created_at DESC')

        return_response(sorted_submissions, 'user_submissions')
      end
    end
  end
end
