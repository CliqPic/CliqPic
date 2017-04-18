class ScrapePublicImagesJob < ApplicationJob
  queue_as :default

  include InstagramHelper
  include JobDelayHelper

  def perform(event_id, user_id=nil)
    user_id ||= Event.select(:user_id).find(event_id).user_id
    user = User.find(user_id)

    ig_client = client_for(user)

    # Get public media

    # Iterate over found media
    # - find_or_create users based on ids on media
    # - Generate invitation records between the user and event
    # - Create image records
  end
end
