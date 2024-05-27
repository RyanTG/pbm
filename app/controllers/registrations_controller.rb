class RegistrationsController < Devise::RegistrationsController
  respond_to :json
  prepend_before_action :create, only: [:create]

  def create
    @user = User.new(user_params)
    if @user.security_test =~ /pinball/i
      if @user.save
        redirect_to root_path, notice: 'Please confirm your account. A link has been emailed to you. If you do not see it, check your SPAM!'
      else
        render action: 'new'
      end
    else
      build_resource(sign_up_params)
      clean_up_passwords(resource)
      flash.now[:alert] = 'You failed the security test. Please go back and try again.'
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :security_test, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :username, :is_disabled, :is_super_admin)
  end
end
