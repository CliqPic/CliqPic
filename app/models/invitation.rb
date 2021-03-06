class Invitation < ApplicationRecord
  belongs_to :event, inverse_of: :invitations
  belongs_to :user, optional: true, inverse_of: :invitations

  after_destroy :detach_user_from_event, unless: 'self.user_id.nil?'

  after_save :scrape_images, unless: 'self.user_id.nil?'

  after_commit :send_invite_email, on: :create, unless: 'self.email.blank? or self.user_id'

  # Either a user or an email is required
  validates_presence_of :user_id, if: 'self.email.blank?'

  def self.from_invite_hash(invite_hash)
    dec = Base64.urlsafe_decode64(invite_hash)

    parts = dec.split(':')

    raise InvalidHash unless parts.length == 3

    event_id, invite_id, = parts[0,2]

    invite = find(invite_id)

    raise AlreadyRedeemed unless invite.user_id.nil?
    raise InvalidHash if event_id.to_i != invite.event_id

    invite
  rescue ActiveRecord::RecordNotFound
    raise Revoked
  end

  def scrape_images
    # If existing user attached to invite, need to scrape
    ScrapeImagesJob.perform_later(self.user_id)
  end

  def detach_user_from_event
    DetachUserFromEventJob.perform_later(self.event_id, self.user_id)
  end

  def send_invite_email
    ApplicationMailer.send_invite(self).deliver
  end

  def build_invite_hash
    @_invite_hash = begin
                      invite_hash = "#{self.event_id}:#{self.id}:"
                      if invite_hash.length < 30
                        invite_hash += SecureRandom.random_bytes(30 - invite_hash.length)
                      end

                      Base64.urlsafe_encode64(invite_hash, padding: false)
                    end
  end

  class Error < ::StandardError
  end

  class AlreadyRedeemed < Error
  end

  class InvalidHash < Error
  end

  class Revoked < Error
  end
end
