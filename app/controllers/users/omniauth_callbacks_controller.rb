class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def instagram
    @user = User.from_omniauth(omniauth_data)

    if @user.access_token != omniauth_data.credentials.token
      # This will be saved by the `sign_in_and_redirect` method below
      @user.access_token = omniauth_data.credentials.token
    end

    # Set the user's time zone, if it's been set in the session already
    @user.time_zone = request.session[:time_zone] if request.session[:time_zone]

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      # FIXME: Even necessary?
      session["devise.instagram_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  protected

  def omniauth_data
    request.env['omniauth.auth']
  end

  def user_root_path
    dashboard_path
  end
end
