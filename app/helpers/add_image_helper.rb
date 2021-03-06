module AddImageHelper
  # FIXME: These can be combined pretty easily, I think.
  def add_images_by_id(image_ids)
    return unless image_ids
    images = Image.find(image_ids)

    images.each { |i| add_image(i) }
  end

  def add_image_by_id(image_id)
    image = Image.find(image_id)

    add_image(image)
  end

  def prune_images_to(image_ids)
    add_images_by_id(image_ids)

    self.images.where.not(id: image_ids).each { |i| detach_image(i) }
  end

  def add_image(image)
    if self.respond_to?(:scanned_images)
      Event.incr_scanned_images(self.id)
    end

    image_ownership_id = image.send(:"#{self.class.to_s.underscore}_id")

    # Don't bother adding an image that's already attached
    return if image_ownership_id == self.id

    working_image = if image_ownership_id.nil?
                      image
                    else
                      image.dup
                    end

    # This should prevent images already assigned to albums from being copied again
    working_image.album_id = nil

    # This doesn't mean a lot outside of albums
    working_image.order = if self.is_a? Album
                            self.reload
                            self.images.count + 1
                          end

    working_image.send(:"#{self.class.to_s.underscore}_id=", self.id)

    working_image.save
  rescue ActiveRecord::RecordNotUnique
    # Do nothing in this case
    # Everything is working as intended
  end

  def detach_image(image)
    # ignore if image has an album, dont detach
    # just because an event no longer matches it.
    return if self.is_a?(Event) and image.album_id

    # Keep track of images we've seen so we can display them
    if self.respond_to?(:scanned_images) 
      Event.incr_scanned_images(self.id)
    end

    # No point detaching what isnt attached anyway
    return nil if image.send(:"#{self.class.to_s.underscore}_id").nil?

    # Just in case
    return nil unless image.send(:"#{self.class.to_s.underscore}_id") == self.id

    # If there's more than one of this image, we can safely delete it
    if Image.where(event_id: image.event_id, thumbnail_url: image.thumbnail_url).count > 1
      image.destroy
    else
      image.send(:"#{self.class.to_s.underscore}_id=", nil)
      image.save
    end
  end

  protected

  def detach_all_images
    self.images.each { |img| detach_image(img) }
  end
end
