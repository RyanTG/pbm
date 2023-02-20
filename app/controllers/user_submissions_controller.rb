class UserSubmissionsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @user_submission = UserSubmission.new(user_submission_params)
    if @user_submission.save
      redirect_to @user_submission, notice: 'UserSubmission was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def user_submission_params
    params.require(:user_submission).permit(:region_id, :user, :user_name, :user_id, :submission_type, :submission, :location, :location_name, :location_id, :city_name, :comment, :high_score, :machine, :machine_id, :machine_name)
  end
end
