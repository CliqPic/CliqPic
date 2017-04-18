module InstagramHelper
  def client_for(user)
    Instagram.client(access_token: user.access_token)
  end

  # Sets fields on the image based on the data returned from instagram
  def process_ig_to_image(image, ig_data)
    image.instagram_link = ig_data.link

    image.created_on_instagram_at = Time.at(ig_data.created_time.to_i)

    image.thumbnail_url = ig_data.images.thumbnail.url
    image.low_res_url   = ig_data.images.low_resolution.url
    image.high_res_url  = ig_data.images.standard_resolution.url

    # TODO: Store hashtags as a text array?
    image.hashtags = ig_data.tags.join(',')

    unless ig_data.location.nil?
      image.lat = ig_data.location.latitude
      image.lon = ig_data.location.longitude
    end
  end
end
