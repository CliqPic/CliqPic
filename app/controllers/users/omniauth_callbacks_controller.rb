class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def instagram
    @user = User.from_omniauth(omniauth_data)

    Rails.logger.debug omniauth_data.inspect

    if @user.access_token != omniauth_data.credentials.token
      # This will be saved by the `sign_in_and_redirect` method below
      @user.access_token = omniauth_data.credentials.token
    end

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
