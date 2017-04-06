class ZippedImageMailer < ApplicationMailer
  default from: 'no-reply@cliqpic.com'

  def send_zip(user, album_name, zip_path)
    @user = user
    @album_name = album_name
    attachments["#{@album_name}.zip"] = File.read(zip_path)

    mail(to: @user.email, subject: "Images for '#{@album_name}'")
  end
end
