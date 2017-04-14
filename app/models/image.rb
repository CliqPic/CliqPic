class Image < ApplicationRecord
  belongs_to :user
  belongs_to :event, optional: true
  belongs_to :album, optional: true

  after_create :queue_image_processor, if: 'self.event_id.nil?'

  # Completely detach this image if it's being detached from the event
  before_save :detach_completely!, if: 'self.event_id_changed? and self.event_id.nil? and self.album_id'

  def queue_image_processor
    ProcessImageToEventJob::FanoutEventsJob.perform_later(self.id, self.user_id)
  end

  def detach_completely!
    self.album.detach_image(self)
  end
end
