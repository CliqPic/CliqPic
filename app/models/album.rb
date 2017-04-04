class Album < ApplicationRecord
  belongs_to :event
  has_many :images

  validates :name, presence: true

  include AlbumsImageHelper

  before_destroy :detach_all_images
end
