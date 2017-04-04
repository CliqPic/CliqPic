class Event < ApplicationRecord
  belongs_to :user
  has_many :albums
  has_many :images

  def placeholder_image
    if images.size > 0
      images.first.thumbnail_url
    else
      "http://placehold.it/700?text=#{ fetching_images ? 'Looking+for+Images' : 'No+Images+Found'}"
    end
  end
end
