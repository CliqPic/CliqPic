class ScrapeImagesJob < ApplicationJob
  queue_as :default

  DEFAULT_COUNT = 20

  def perform(user_id, max_id=nil)
    user = User.find user_id
    ig_client = Instagram.client(access_token: user.access_token)

    images = ig_client.user_recent_media(user.uid, max_id: max_id, count: DEFAULT_COUNT)

    last_image_created = false

    images.each do |image|
      # Skip other forms of media
      next if image.type != 'image'

      last_image_created = false

      user.images.where(instagram_id: image.id).first_or_create do |i|
        i.instagram_link = image.link

        i.created_on_instagram_at = Time.at(image.created_time.to_i)

        i.thumbnail_url = image.images.thumbnail.url
        i.low_res_url   = image.images.low_resolution.url
        i.high_res_url  = image.images.standard_resolution.url

        # TODO: Store hashtags as a text array?
        i.hashtags = image.tags.join(',')

        i.lat = image.location.latitude
        i.lon = image.location.longitude

        last_image_created = true
      end
    end

    if images.count == DEFAULT_COUNT and last_image_created
      # If we got a full page and the last image we grabbed was new, queue a job
      # to grab the next page
      self.class.perform_later(user_id, images.last.id)
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
