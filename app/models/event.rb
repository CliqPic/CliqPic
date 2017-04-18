class Event < ApplicationRecord
  belongs_to :user
  has_many :albums, dependent: :destroy
  has_many :images
  has_many :invitations, dependent: :destroy
  has_many :invitees, through: :invitations, source: :user

  before_destroy :detach_all_images

  before_create :fetching_images!
  before_save :fetching_images!, if: 'self.picture_inclusion_data_changed?'
  before_save :clear_lat_lon,    if: 'self.location_changed? and self.location.blank?'

  after_commit :queue_image_processor, on: :create
  # Update images only if something key about the event changes
  after_save :queue_image_processor, if: 'self.picture_inclusion_data_changed?'

  validates_presence_of :hashtags
  # validate do
  #   if self.hashtags.blank? and (self.start_time.blank? or self.end_time.blank?) and self.location.blank?
  #     errors.add(:base, :invalid, message: 'Must supply a date range, location, or hashtags')
  #   end
  # end

  include AddImageHelper
  include OwnershipHelper

  def picture_inclusion_data_changed?
    self.start_time_changed? or
      self.end_time_changed? or
      self.hashtags_changed? or
      self.location_changed? or
      self.loc_lat_changed? or
      self.loc_lon_changed?
  end

  def fetching_images!
    self.fetching_images = true
  end

  def clear_lat_lon
    self.loc_lat = nil
    self.loc_lon = nil
  end

  def queue_image_processor
    if self.location_changed? and not self.location.blank?
      GeocodeLocationJob.perform_later(self.id)
    else
      ProcessImageToEventJob::FanoutImagesJob.perform_later(self.id)
      ProcessImageToEventJob::FanoutInviteesJob.perform_later(self.id)
      ScrapePublicImagesJob.perform_later(self.id)
      ScrapeImagesJob.perform_later(self.user_id)
    end
  end
end
