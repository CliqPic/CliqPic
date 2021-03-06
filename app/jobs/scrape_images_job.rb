class ScrapeImagesJob < ApplicationJob
  queue_as :scraper

  include InstagramHelper

  DEFAULT_COUNT = 20

  include JobDelayHelper

  after_enqueue do |job|
    unless job.provider_job_id.nil?
      # If this job was successfully queued, queue up a job to also scrape the
      # users this user follows on IG, except when we're already scraping for a
      # follower
      user_id = job.arguments.first

      unless (job.arguments.second and job.arguments.second[:images_for])
        ProcessFollowedUsersJob.set(wait: 10.seconds).perform_later(user_id)
      end

      Event.where(owner_id: user_id).pluck(:id).map { |id| Event.incr_image_process_counter(id) }
    end
  end

  after_perform do |job|
    Event.where(owner_id: job.arguments.first).pluck(:id).map { |id| Event.decr_image_process_counter(id) }
  end

  def perform(user_id, options={})
    calling_user = User.find user_id

    unless calling_user.access_token or options[:access_token]
      msg = "No access token on #{user_id} when ScrapeImagesJob was called, aborting"
      puts msg
      logger.error(msg)
      return
    end

    # Fighting race conditions
    calling_user.access_token ||= options[:access_token]

    ig_client = client_for(calling_user)

    user = if options[:images_for]
             User.find options[:images_for]
           else
             calling_user
           end

    ig_images = ig_client.user_recent_media(user.uid, max_id: options[:max_id], count: DEFAULT_COUNT)

    last_image_created = false

    # Any other unassigned images should get their chance at being attached
    user.images.where(event_id: nil).map(&:queue_image_processor)

    ig_images.each do |image_data|
      # Add new images, give them a chance to attach.
      # Skip other forms of media
      next if image_data.type != 'image'

      last_image_created = false

      user.images.where(instagram_id: image_data.id, thumbnail_url: image_data.images.thumbnail.url, event_id: nil).first_or_create do |image|
        process_ig_to_image(image, image_data)

        last_image_created = true
      end
    end

    if ig_images.count == DEFAULT_COUNT and last_image_created
      # If we got a full page and the last image we grabbed was new, queue a job
      # to grab the next page
      self.class.perform_later(user_id, options.merge(max_id: ig_images.last.id))
    end

  rescue Instagram::BadRequest
    # This usually means super bad shit is happening
    # Like, Instagram is blocking us bad
    puts "Bad Request when pulling images for user #{user_id}"
    logger.error("Bad Request when pulling images for user #{user_id}")
  rescue Instagram::Error
    # These are usually "try again later" type errors
    # So, we'll just requeue this one to wait a bit before trying again
    self.class.set(wait: 30.seconds).perform_later(user_id, max_id)
  end

  class FanoutInviteesJob < ApplicationJob
    queue_as :scraper

    include EventProcessingHelper

    def get_event_id(job)
      job.arguments.first
    end

    def perform(event_id)
      invitations = Invitation.select(:user_id).where(event_id: event_id).where("user_id is not null")

      invitations.each do |i|
        ScrapeImagesJob.perform_later(i.user_id)
      end
    end
  end
end
