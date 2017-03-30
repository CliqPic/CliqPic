class Event < ApplicationRecord
  belongs_to :user
  has_many :albums
  has_many :images
end
