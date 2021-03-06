class ZipImagesJob < ApplicationJob
  queue_as :filter

  def perform(album_id, user_id, *args)
    user  = User.find(user_id)
    album = Album.find(album_id)

    folder_name = album.cache_key.gsub('/', '-')

    path = Rails.root / 'tmp' / folder_name
    safe_path = Shellwords.escape(path)
    final_path = "#{path}.zip"

    unless File.exists? final_path
      image_urls = album.images.pluck(:high_res_url)

      # Download all images to the local tmp directory and zip them up, removing
      # the images when we're done.  Long parameters used to ease debugging.
      `mkdir -p #{safe_path} &&\
       cd #{safe_path} &&\
       curl --silent --remote-name-all #{image_urls.shelljoin} &&\
       cd .. &&\
       zip --quiet --recurse-paths --junk-paths #{final_path.shellescape} #{safe_path} &&\
       rm -r #{safe_path}`

      raise 'Unable to create zip file' unless File.exists? final_path
    end

    ApplicationMailer.send_zip(user, album.name, final_path).deliver_now

    File.delete(final_path)
  end
end
