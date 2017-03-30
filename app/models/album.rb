class Album < ApplicationRecord
  belongs_to :event
  has_many :images
end
