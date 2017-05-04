class ProcessImageToEventJob < ApplicationJob
  queue_as :processor

  include JobDelayHelper
  include EventProcessingHelper

  def get_event_id(job)
    job.arguments.second
  end

  def perform(image_id, event_id)
    image = Image.find image_id
    event = Event.where(id: event_id).first
    return if not event

    # Only users that should have images attached to this event
    event.detach_image(image) unless event.user_ids.any? { |id| id == image.user_id }

    # Check if the image hashtags include all the event hashtags
    unless event.hashtags.blank?
      image_tags = Set.new(image.hashtags.try(:downcase).to_s.split(','))
      event_tags = Set.new(event.hashtags.try(:downcase).to_s.split(','))

      # NOTE: We try to detach the image here in case it was attached to this
      # event but should no longer be
      return event.detach_image(image) unless event_tags.intersect? image_tags
    end

    # Check if the image was taken near the location of the event
    unless event.loc_lat.blank? or event.loc_lon.blank? or image.lat.blank? or image.lon.blank?
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
  rescue ActiveRecord::RecordNotFound
    # Looks like we couldn't find a record
    # This normally happens if an event gets deleted not long after being created
  end

  # This allows one job to be quickly queued from the image during creation
  # that will fan out to all a user's events without having to take the time
  # to iterate over all of them while it's being created
  class FanoutEventsJob < ApplicationJob
    queue_as :processor

    def perform(image_id, user_id=nil)
      user = if user_id
               User.find(user_id)
             else
               Image.find(image_id).user
             end

      event_ids = user.search_for_events

      event_ids.each do |event_id|
        ProcessImageToEventJob.perform_later(image_id, event_id)
      end
    end
  end

  # This allows one job to be quickly queued from the event during creation that
  # will fan out all of the given - or the event's - user's images and check if
  # They should be assigned to this event or not.
  class FanoutImagesJob < ApplicationJob
    queue_as :processor

    # Queue a ProcessImageToEventJob for each image found
    # Has two modes of operation based on inputs:
    # when user_id == nil
    #   Queue a job for each image owned by this event's user
    # when user_id.is_a? Integer
    #   Queue a job for each image owned by the given user
    def perform(event_id, user_id=nil)
      user_id ||= Event.select(:owner_id).find(event_id).owner_id

      images = Image.select(:id).where(user_id: user_id)

      # Since a given user may have 10's of thousands of images, process images
      # in batches to reduce total overhead of the worker
      images.in_batches do |batch|
        batch.each { |i| ProcessImageToEventJob.perform_later(i.id, event_id) }
      end
    rescue ActiveRecord::RecordNotFound
      # Looks like we couldn't find a record
      # This normally happens if an event gets deleted not long after being created
    end
  end

  class FanoutUsersJob < ApplicationJob
    queue_as :processor

    def perform(event_id)
      event = Event.where(id: event_id).first
      return if not event

      event.user_ids.each { |user_id| FanoutImagesJob.perform_later(event_id, user_id) }
    end
  end
end
