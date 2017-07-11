class StaticController < ApplicationController
  before_action :redirect_signed_in, only: [ :index ]

  if Rails.env.production?
    before_action :redirect_prod_login, only: [ :index ]
  end

  def index
  end

  def redirect_signed_in
    redirect_to dashboard_path if user_signed_in?
  end

  # This only runs when Rails is running in production
  def redirect_prod_login
    # Ensure that no flash messages are carried over to the next login
    flash.clear
    redirect_to 'app.cliqpic.com/users/auth/instagram'
  end
end
