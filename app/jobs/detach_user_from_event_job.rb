class DetachUserFromEventJob < ApplicationJob
  queue_as :processor

  def perform(event_id, user_id, process_followers=true)
    event = Event.find event_id

    # Don't detach users that still belong on the event
    # This should neatly cover cases where users share followers
    return if event.user_ids.any? { |id| id == user_id }

    event.images.where(user_id: user_id).each do |image|
      event.detach_image(image)
    end

    if process_followers
      user = User.find user_id

      user.followed_users.select(:id).each do |followed|
        self.class.perform_later(event_id, followed.id, false)
      end
    end

  rescue ActiveRecord::RecordNotFound
    # Usually means the event couldn't be found
    # Regardless, there's generally nothing we can do about this
  end
end
