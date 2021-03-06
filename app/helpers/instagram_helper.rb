module InstagramHelper
  def client_for(user)
    Instagram.client(access_token: user.access_token)
  end

  # Sets fields on the image based on the data returned from instagram
  def process_ig_to_image(image, ig_data, original_tag=nil)
    if ig_data.respond_to?(:link)
      image.instagram_link = ig_data.link

      image.created_on_instagram_at = Time.at(ig_data.created_time.to_i).utc

      image.thumbnail_url = ig_data.images.thumbnail.url
      image.low_res_url   = ig_data.images.low_resolution.url
      image.high_res_url  = ig_data.images.standard_resolution.url

      # TODO: Store hashtags as a text array?
      image.hashtags = ig_data.tags.join(',')

      unless ig_data.location.nil?
        image.lat = ig_data.location.latitude
        image.lon = ig_data.location.longitude
      end
    else
      image.instagram_link = "https://www.instagram.com/p/#{ig_data["code"]}"

      image.created_on_instagram_at = Time.at(ig_data["date"]).utc

      image.thumbnail_url = ig_data["thumbnail_src"]
      image.low_res_url   = ig_data["display_src"]
      image.high_res_url  = ig_data["display_src"]

      # TODO: Store hashtags as a text array?
      tags = ig_data["caption"].try(:match, /#([A-Za-z\-_\d\/\\]+)/).try(:to_a) || []
      image.hashtags = tags[1..-1].uniq.join(',') if tags.size >= 1
    end
  end
end
