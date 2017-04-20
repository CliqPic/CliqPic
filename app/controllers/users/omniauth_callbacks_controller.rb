class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def instagram
    @user = User.from_omniauth(omniauth_data)

    if @user.access_token != omniauth_data.credentials.token
      # This will be saved by the `sign_in_and_redirect` method below
      @user.access_token = omniauth_data.credentials.token
    end

    # This sign in came through an invitation
    if session[:user_email]
      email = session.delete(:user_email)

      @user.email = email if @user.email.blank?

      # Update all invitations that have this email that haven't already been set
      Invitation.where(email: email, user_id: nil).update_all(user_id: @user.id)
    end

    # Set the user's time zone, if it's been set in the session already
    @user.time_zone = request.session[:time_zone] if request.session[:time_zone]

    sign_in_and_redirect @user, event: :authentication
  end

  protected

  def omniauth_data
    request.env['omniauth.auth']
  end

  def user_root_path
    dashboard_path
  end
end
