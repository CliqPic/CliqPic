class ScrapePublicImagesJob < ApplicationJob
  queue_as :default

  include EventProcessingHelper

  def get_event_id(job)
    job.arguments.first
  end

  def perform(event_id, user_id=nil)
    event = Event.select(:id, :owner_id, :hashtags).find(event_id)

    event.hashtags.split(',').each do |tag|
      SearchHashtagsJob.perform_later(event_id, (user_id || event.owner_id), hashtag: tag)
    end
  end

  class SearchHashtagsJob < ApplicationJob
    queue_as :default

    include InstagramHelper
    include JobDelayHelper

    DEFAULT_COUNT = 20

    extend EventProcessingHelper

    def self.get_event_id(job)
      job.arguments.first
    end

    def perform(event_id, user_id, options={})
      event = Event.find(event_id)
      user = User.find(user_id)

      ig_client = client_for(user)

      # Get public media

      possible_images = ig_client.tag_recent_media(options[:hashtag],
                                                   max_id: options[:max_id])

      last_image_created = false
      # Keep track of users to keep DB requests down
      image_users = {}

      possible_images.each do |p_image|
        next if p_image.type != 'image'

        last_image_created = false

        ig_user = p_image.user

        image_users[ig_user.id] ||= User.where(provider: 'instagram', uid: ig_user.id).first_or_create do |u|
          u.name = ig_user.full_name
        end

        local_user = image_users[ig_user.id]

        event.invitations.where(user_id: local_user.id).first_or_create

        local_user.images.where(instagram_id: p_image.id, thumbnail_url: p_image.images.thumbnail.url).first_or_create do |image|
          process_ig_to_image(image, p_image)

          last_image_created = true
        end
      end

      if possible_images.count == DEFAULT_COUNT and last_image_created
        self.class.perform_later(event_id, user_id, options.merge(max_id: possible_images.last.id))
      end

    rescue Instagram::BadRequest
      # This usually means super bad shit is happening
      # Like, Instagram is blocking us bad
      logger.error("Bad Request when pulling pulic images")
    rescue Instagram::Error
      # These are usually "try again later" type errors
      # So, we'll just requeue this one to wait a bit before trying again
      self.class.set(wait: 30.seconds).perform_later(event_id, user_id, options)
    end
  end
end
