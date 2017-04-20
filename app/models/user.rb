class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable, :rememberable, :trackable,
         :validatable, :lockable, :omniauthable,
         # We don't actually provide a login form, but Devise doesn't seem to
         # work very well if you don't provide this
         :database_authenticatable,
         omniauth_providers: [:instagram]

  has_many :invitations, dependent: :destroy
  has_many :events, foreign_key: :owner_id, dependent: :destroy
  has_many :invited_events, through: :invitations, source: :event
  has_many :albums, through: :events
  has_many :images, dependent: :destroy

  # Self referential has_and_belongs_to_many relationships suck
  
  has_and_belongs_to_many :followed_users,
                          class_name: 'User',
                          join_table: :users_followers,
                          association_foreign_key: :user_id,
                          foreign_key: :follower_id,
                          uniq: true,
                          inverse_of: :followers

  has_and_belongs_to_many :followers,
                          class_name: 'User',
                          join_table: :users_followers,
                          foreign_key: :user_id,
                          association_foreign_key: :follower_id,
                          uniq: true,
                          inverse_of: :followed_users

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email.to_s
      user.name  = auth.info.name.to_s
      user.password = Devise.friendly_token[0,25]
    end
  end

  def search_for_events
    @_all_events ||= Event.find_by_sql %[ SELECT DISTINCT "events".*
                                              FROM "events"
                                          LEFT JOIN "users_followers"
                                              ON "users_followers"."user_id" = #{self.id}
                                          LEFT JOIN "invitations"
                                              ON "invitations"."user_id" = #{self.id}
                                              OR "invitations"."user_id" = "users_followers"."follower_id"
                                          WHERE "events"."owner_id" = #{self.id}                      -- My events
                                             OR "events"."owner_id" = "users_followers"."follower_id" -- Followers events
                                             OR "events"."id" = "invitations"."event_id"              -- Any invited event
                                                                                                      -- for me or followers
                                        ]
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

  protected

  def email_required?; false; end
end
