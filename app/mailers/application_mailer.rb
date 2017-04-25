class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@cliqpic.com'
  layout 'mailer'

  def send_zip(user, album_name, zip_path)
    @user = user
    @album_name = album_name
    attachments["#{@album_name}.zip"] = File.read(zip_path)

    mail(to: @user.email, subject: "Images for '#{@album_name}'")
  end

  def send_invite(invitation)
    @invitation = invitation
    @event = invitation.event
    @user = @event.user

    mail(to: invitation.email, subject: "Invite Request - #{@event.name}")
  end
end
