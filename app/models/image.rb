class Image < ApplicationRecord
  belongs_to :user
  belongs_to :event, optional: true
  belongs_to :album, optional: true

  after_create :queue_image_processor, if: 'self.event_id.nil?'

  # Completely detach this image if it's being detached from the event
  before_save :detach_completely!, if: 'self.event_id_changed? and self.event_id.nil? and self.album_id'

  scope :in_order, -> { order(order: :asc, id: :desc) }

  BUCKET_URL_TEMPLATE = "https://s3.amazonaws.com/cliq-pic-images/#{Rails.env}/%{id}/%{type}%{ext}"

  def queue_image_processor
    ProcessImageToEventJob::FanoutEventsJob.perform_later(self.id, self.user_id)
  end

  def detach_completely!
    self.album.detach_image(self)
  end

  def apply_filter(filter)
    if filter == 'revert'
      original = Image.where(instagram_id: self.instagram_id).where("thumbnail_url ~ 'instagram'").first

      self.thumbnail_url = original.thumbnail_url
      self.low_res_url   = original.low_res_url
      self.high_res_url  = original.high_res_url

      if(Image.where(thumbnail_url: self.thumbnail_url, album_id: self.album_id).first)
        # The only reason this would fail is if the album already has the original
        # version of this image, so we destroy this guy.
        destroy
      else
        detach_completely! unless self.save
      end
    else

      # Keep a copy of this image attached to the event
      copy = self.dup
      copy.album_id = nil
      # If this fails, it's okay.  It means that we already have a copy of the image
      copy.save rescue nil

      # Set up the URLs we'll use to access them
      self.thumbnail_url = BUCKET_URL_TEMPLATE % { id: self.id, type: 'thumbnail', ext: File.extname(self.thumbnail_url) }
      self.low_res_url   = BUCKET_URL_TEMPLATE % { id: self.id, type: 'low_res',   ext: File.extname(self.low_res_url) }
      self.high_res_url  = BUCKET_URL_TEMPLATE % { id: self.id, type: 'high_res',  ext: File.extname(self.high_res_url) }

      self.save

      ApplyFilterJob.perform_later(self.id,
                                   filter: filter,
                                   original_thumbnail: copy.thumbnail_url,
                                   original_low_res: copy.low_res_url,
                                   original_high_res: copy.high_res_url
                                  )
    end
  end
end
