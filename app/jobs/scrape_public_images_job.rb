class ScrapePublicImagesJob < ApplicationJob
  queue_as :default

  include EventProcessingHelper

  def get_event_id(job)
    job.arguments.first
  end

  def perform(event_id, user_id=nil)
    event = Event.select(:id, :owner_id, :hashtags).find(event_id)
    Event.where(id: event_id).update_all("image_process_counter = image_process_counter + #{event.hashtags.blank? ? 0 : event.hashtags.split(',').count}")

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

    after_perform do |job|
      Event.where(id: job.arguments.first).update_all('image_process_counter = image_process_counter - 1,
                                                             fetching_images = ((image_process_counter - 1) != 0)')
    end

    def perform(event_id, user_id, options={})

      event = Event.find(event_id)
      user = User.find(user_id)

      unless user.access_token
        msg = "No access token on #{user_id} when ScrapeImagesJob was called, aborting"
        puts msg
        logger.error(msg)
        return
      end

      ig_client = client_for(user)

      # Get public media

      possible_images = InstaScrape.hashtag(options[:hashtag], include_meta_data: true)

      last_image_created = false
      # Keep track of users to keep DB requests down
      image_users = {}

      possible_images.each do |p_image|
        last_image_created = false

        # Scraper cant get user ids. So we just make a user out of the hashtag.
        # this way we can use the invitation system. It's hacky, but it's also
        # an MVP.
        ig_user_id = options[:hashtag]

        image_users[ig_user_id] ||= User.where(uid: ig_user_id).first
        unless image_users[ig_user_id]
          image_users[ig_user_id] = User.new(provider: 'instagram', uid: ig_user_id)
          image_users[ig_user_id].password = "123456"
          image_users[ig_user_id].save
        end

        local_user = image_users[ig_user_id]

        event.invitations.where(user_id: local_user.id, public: true).first_or_create

        local_user.images.where(instagram_id: p_image.link.match(/p\/([A-Za-z_\-\d]+)\/\?/)[1], thumbnail_url: p_image.link).first_or_create do |image|
          process_ig_to_image(image, p_image)
          last_image_created = true
        end
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
