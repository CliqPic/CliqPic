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
      user.email = auth.info.email.to_s
      user.name  = auth.info.name.to_s
      user.password = Devise.friendly_token[0,25]
    end
  end

  def name
    [self.first_name, self.middle_name, self.last_name].join(' ').strip
  end

  # Sets the name fields based on a full name
  def name=(new_name)
    name_parts = new_name.split(' ')

    self.first_name = name_parts.shift.to_s
    self.last_name = name_parts.pop.to_s
    self.middle_name = name_parts.join(' ')
  end
end
