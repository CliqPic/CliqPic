class Event < ApplicationRecord
  belongs_to :user
  has_many :albums, dependent: :destroy
  has_many :images

  before_destroy :detach_all_images

  after_commit :queue_image_processor, on: :create
  # Update images only if something key about the event changes
  after_save :queue_image_processor, if: 'self.start_time_changed? or
                                          self.end_time_changed? or
                                          self.hashtags_changed? or
                                          self.location_changed?'

  validate do
    if self.hashtags.blank? and (self.start_time.blank? or self.end_time.blank?) and self.location.blank?
      errors.add(:base, :invalid, message: 'Must supply a date range, location, or hashtags')
    end
  end

  include AddImageHelper

  def queue_image_processor
    ProcessImageToEventJob::FanoutImagesJob.perform_later(self.id)
    ScrapeImagesJob.perform_later(self.user_id)
  end
end
