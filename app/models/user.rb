class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable, :rememberable, :trackable,
         :validatable, :lockable, :omniauthable,
         omniauth_providers: [:instagram]

  devise :database_authenticatable if Rails.env.development?

  has_many :events
  has_many :images

  def self.from_omniauth(auth)
    where(uid: auth.uid).first_or_create do |user|
      # Garbage email just so I can get auth working
      user.email = "#{auth.uid}@instagram.com"
      user.password = Devise.friendly_token[0,25]
    end
  end
end
