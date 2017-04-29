class ProcessFollowedUsersJob < ApplicationJob
  queue_as :scraper

  include InstagramHelper
  include JobDelayHelper

  def perform(user_id)
    return
    user = User.find user_id

    client = client_for(user)

    followed_users = client.user_follows

    followed_users.each do |ig_data|
      f_user = User.where(provider: 'instagram', uid: ig_data.id).first_or_create do |u|
        u.name = ig_data.full_name.to_s
        u.email = ""
        u.password = Devise.friendly_token[0,25]
      end

      f_user.followers << user rescue ActiveRecord::RecordNotUnique

      # Grab all the calling user's events and add the new user to them
      # as an invitee
      user.events.each do |event|
        # Create invitations for each event for this user
        event.invitations.where(user_id: f_user.id).first_or_create!
      end

      ScrapeImagesJob.set(wait: 5.seconds).perform_later(user_id, images_for: f_user.id)
    end
  end
end
