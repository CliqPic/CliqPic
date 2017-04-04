class Image < ApplicationRecord
  belongs_to :user
  belongs_to :event, optional: true
  belongs_to :album, optional: true
end
