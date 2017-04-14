class Album < ApplicationRecord
  belongs_to :event
  has_one :user, through: :event
  has_many :images

  validates :name, presence: true

  include AddImageHelper

  before_destroy :detach_all_images

  def zip_images_for(user)
    ZipImagesJob.perform_later(self.id, user.id)
  end
end
