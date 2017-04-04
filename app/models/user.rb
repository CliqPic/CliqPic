class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable, :rememberable, :trackable,
         :validatable, :lockable, :omniauthable,
         # We don't actually provide a login form, but Devise doesn't seem to
         # work very well if you don't provide this
         :database_authenticatable,
         omniauth_providers: [:instagram]

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
