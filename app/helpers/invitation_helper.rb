module InvitationHelper
  def process_invitations(invites)
    emails = case invites
             when Array
               invites
             when String
               invites.split(',')
             end

    # Ensure all the invites we have are already here
    existing = self.invitations.where(email: emails)

    # looks like we need to add some invitations
    if existing.length < emails.length
      existing_emails = existing.pluck(:email)
      new_emails = emails.reject { |e| existing_emails.include? e }

      new_emails.each { |e| self.invitations.create(email: e) }
    end

    removed = self.invitations.where.not(email: emails)

    removed.destroy_all
  end
end
