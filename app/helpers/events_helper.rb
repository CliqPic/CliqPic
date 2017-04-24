module EventsHelper
  def display_image(event)
    album = event.albums.first
    image = ((album.images.in_order.first rescue nil) || event.images.first)

    if image
      image.low_res_url
    else
      "http://placehold.it/700?text=#{ event.fetching_images ? 'Looking+for+Images' : 'No+Images+Found'}"
    end
  end
end
