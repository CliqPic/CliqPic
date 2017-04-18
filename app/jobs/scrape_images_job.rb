class ScrapeImagesJob < ApplicationJob
  queue_as :default

  include InstagramHelper

  DEFAULT_COUNT = 20

  include JobDelayHelper

  after_enqueue do |job|
    # If this job was successfully queued, queue up a job to also scrape the
    # users this user follows on IG, except when we're already scraping for a
    # follower
    unless job.provider_job_id.nil? or
          (job.arguments.second and job.arguments.second[:images_for])
      user_id = job.arguments.first

      ProcessFollowedUsersJob.set(wait: 10.seconds).perform_later(user_id)
    end
  end

  def perform(user_id, options={})
    calling_user = User.find user_id
    ig_client = client_for(calling_user)

    user = if options[:images_for]
             User.find options[:images_for]
           else
             calling_user
           end

    ig_images = ig_client.user_recent_media(user.uid, max_id: options[:max_id], count: DEFAULT_COUNT)

    last_image_created = false

    ig_images.each do |image_data|
      # Skip other forms of media
      next if image_data.type != 'image'

      last_image_created = false

      user.images.where(instagram_id: image_data.id).first_or_create do |image|
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
  rescue Instagram::Error
    # These are usually "try again later" type errors
    # So, we'll just requeue this one to wait a bit before trying again
    self.class.set(wait: 30.seconds).perform_later(user_id, max_id)
  end
end
