module AlbumsImageHelper
  # FIXME: These can be combined pretty easily, I think.
  def add_images_by_id(image_ids)
    images = Image.where(event_id: self.event_id).find(image_ids)

    images.each { |i| add_image(i) }
  end

  def add_image_by_id(image_id)
    image = Image.where(event_id: self.event_id).find(image_id)

    add_image(image)
  end

  def zip_images_for(user)
    ZipImagesJob.perform_later(self.id, user.id)
  end

  protected

  def add_image(image)
    working_image = unless image.album_id.nil? or image.album_id == self.id
                      image.dup
                    else
                      image
                    end

    working_image.album_id = self.id

    working_image.save
  end

  def detach_all_images
    self.images.each { |img| detach_image(img) }
  end

  def detach_image(image)
    # Just in case
    return nil unless image.album_id == self.id

    # If there's more than one of this image, we can safely delete it
    if Image.where(thumbnail_url: image.thumbnail_url, event_id: self.event_id).count > 1
      image.destroy
    else
      image.album_id = nil
      image.save
    end
  end
end
