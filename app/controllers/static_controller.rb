class StaticController < ApplicationController
  def index
    puts Rails.application.config.assets.manifest

    redirect_to dashboard_path if user_signed_in?
  end
end
