class Event < ApplicationRecord
  belongs_to :owner, class_name: 'User'
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

  include AddImageHelper
  include InvitationHelper

  def owned_by?(user)
    user and self.owner_id == user.id
  end

  def users
    @_users ||= User.find_by_sql [%[ SELECT DISTINCT "users".*
                                         FROM "users"
                                         LEFT JOIN "invitations"
                                             ON "invitations"."event_id" = :id
                                         LEFT JOIN "users_followers"
                                             ON "users_followers"."follower_id" = :owner_id
                                             OR "users_followers"."follower_id" = "invitations"."user_id"
                                         WHERE "users"."id" = :owner_id
                                            OR "users"."id" = "invitations"."user_id"
                                            OR "users"."id" = "users_followers"."user_id"
                                   ],
                                  { id: self.id, owner_id: self.owner_id }
                                 ]
  end

  def reload
    @_users = nil
    super
  end

  def picture_inclusion_data_changed?
    self.start_time_changed? or
      self.end_time_changed? or
      self.hashtags_changed? or
      self.location_changed? or
      self.loc_lat_changed? or
      self.loc_lon_changed? or 
      self.search_public_changed?
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
      ProcessImageToEventJob::FanoutUsersJob.perform_later(self.id)
      ScrapeImagesJob::FanoutInviteesJob.perform_later(self.id)
      ScrapePublicImagesJob.perform_later(self.id) if self.search_public
      ScrapeImagesJob.perform_later(self.owner_id)
    end
  end
end
