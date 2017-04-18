class ProcessImageToEventJob < ApplicationJob
  queue_as :default

  include JobDelayHelper

  after_enqueue do |job|
    event_id = job.arguments.second

    Event.increment_counter(:image_process_counter, event_id) unless job.provider_job_id.nil?
  end

  after_perform do |job|
    event_id = job.arguments.second
    Event.decrement_counter(:image_process_counter, event_id)
    # This is done to prevent concurrency issues.
    # The event should always correctly update even if another job has changed
    # the counter before this statement runs.
    Event.where(id: event_id).update_all('fetching_images = (image_process_counter != 0)')
  end

  def perform(image_id, event_id)
    image = Image.find image_id
    event = Event.find event_id

    # Check if the image hashtags include all the event hashtags
    unless event.hashtags.blank?
      image_tags = Set.new(image.hashtags.to_s.split(','))
      event_tags = Set.new(event.hashtags.to_s.split(','))

      # NOTE: We try to detach the image here in case it was attached to this
      # event but should no longer be
      return event.detach_image(image) unless event_tags.subset? image_tags
    end

    # Check if the image was taken near the location of the event
    unless event.loc_lat.blank? or event.loc_lon.blank?
      distance_in_miles = Geokit::LatLng.distance_between([event.loc_lat, event.loc_lon],
                                                          [image.lat, image.lon],
                                                          units: :miles
                                                         )
      return event.detach_image(image) if distance_in_miles > 0.5
    end

    # Check if the image was taken during the correct time frame for the event
    unless event.start_time.blank? or event.end_time.blank?
       unless image.created_on_instagram_at.between?(event.start_time, event.end_time)
         return event.detach_image(image)
       end
    end

    event.add_image(image)
  end

  # This allows one job to be quickly queued from the image during creation
  # that will fan out to all a user's events without having to take the time
  # to iterate over all of them while it's being created
  class FanoutEventsJob < ApplicationJob
    queue_as :default

    def perform(image_id, user_id=nil)
      user_id ||= Image.find(image_id).user_id

      event_ids = Event.where(user_id: user_id).pluck(:id)
      event_ids += Invitation.where(user_id: user_id).pluck(:event_id)

      event_ids.each do |event_id|
        ProcessImageToEventJob.perform_later(image_id, event_id)
      end
    end
  end

  # This allows one job to be quickly queued from the event during creation that
  # will fan out all of the given - or the event's - user's images and check if
  # They should be assigned to this event or not.
  class FanoutImagesJob < ApplicationJob
    queue_as :default

    # Queue a ProcessImageToEventJob for each image found
    # Has two modes of operation based on inputs:
    # when user_id == nil
    #   Queue a job for each image owned by this event's user
    # when user_id.is_a? Integer
    #   Queue a job for each image owned by the given user
    def perform(event_id, user_id=nil)
      user_id ||= Event.find(event_id).user_id

      images = Image.select(:id).where(user_id: user_id)

      # Since a given user may have 10's of thousands of images, process images
      # in batches to reduce total overhead of the worker
      images.in_batches do |batch|
        batch.each { |i| ProcessImageToEventJob.perform_later(i.id, event_id) }
      end
    end
  end

  class FanoutInviteesJob < ApplicationJob
    queue_as :default

    def perform(event_id)
      invites = Invitation.select(:user_id).where(event_id: event_id)

      invites.each { |i| FanoutImagesJob.perform_later(event_id, i.user_id) }
    end
  end
end
