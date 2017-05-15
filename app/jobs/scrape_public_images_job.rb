class ScrapePublicImagesJob < ApplicationJob
  queue_as :scraper

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
    queue_as :scraper

    include InstagramHelper
    include JobDelayHelper

    DEFAULT_COUNT = 20

    extend EventProcessingHelper

    def self.get_event_id(job)
      job.arguments.first
    end

    after_enqueue do |job|
      Event.incr_image_process_counter(job.arguments.first)
    end

    after_perform do |job|
      Event.decr_image_process_counter(job.arguments.first)
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

      # Get public media

      puts "Searching for #{options[:hashtag]} with #{options[:max_id]} as last id and total new is #{options[:total_new]}"
      possible_images = RubyInstagramScraper.get_tag_media_nodes(options[:hashtag], options[:max_id])

      last_image_created = false
      # Keep track of users to keep DB requests down
      image_users = {}

      total_new = 0

      possible_images["nodes"].each do |p_image|
        next if p_image["is_video"]

        last_image_created = false

        ig_user = p_image["owner"]

        image_users[ig_user["id"]] ||= User.where(uid: ig_user["id"]).first
        unless image_users[ig_user["id"]]
          image_users[ig_user["id"]] = User.new(provider: 'instagram', uid: ig_user["id"])
          image_users[ig_user["id"]].password = "123456"
          image_users[ig_user["id"]].save
        end

        local_user = image_users[ig_user["id"]]

        # Fighting race conditions
        begin
          event.invitations.where(user_id: local_user.id, public: true).first_or_create
        rescue ActiveRecord::RecordNotUnique
        end

        local_user.images.where(instagram_id: p_image["id"], thumbnail_url: p_image["thumbnail_src"]).first_or_create do |image|
          process_ig_to_image(image, p_image, options[:hashtag])
          last_image_created = true
        end
        total_new += 1
      end

      total_new = (options[:total_new] || 0) + total_new

      puts "Possible images is #{possible_images["page_info"]["has_next_page"]} and #{total_new}"
      if total_new < 1000 and possible_images["page_info"]["has_next_page"]
        puts "performing a new guy"
        # If we got a full page and the last image we grabbed was new, queue a job
        # to grab the next page
        self.class.perform_later(event_id, user_id, options.merge(max_id: possible_images["page_info"]["end_cursor"], total_new: total_new))
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
