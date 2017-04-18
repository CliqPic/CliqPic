class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :ensure_access_token

  around_action :user_time_zone

  def ensure_access_token
    sign_out current_user if current_user and current_user.access_token.nil?
  end

  def user_time_zone
    zone = if user_signed_in?
             current_user.time_zone
           else
             request.session[:time_zone]
           end

    return yield if zone.nil?

    Time.use_zone(zone) { yield }
  end

  # /set-tz
  def set_time_zone
    request.session[:time_zone] = params[:time_zone].to_i

    if user_signed_in?
      current_user.time_zone = request.session[:time_zone]
      current_user.save
    end
  end
end
