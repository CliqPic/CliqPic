class ApplyFilterJob < ApplicationJob
  queue_as :filter

  def perform(image_id, options={})
    image_data = Image.find image_id

    bucket = Aws::S3::Bucket.new('cliq-pic-images')

    unless bucket.exists?
      bucket.create(acl: 'public-read')
      bucket.wait_until_exists do
        cors = bucket.cors
        cors.put(cors_configuration: {
                   cors_rules: [{ allowed_methods: %w[GET],
                                  allowed_origins: %w[*]
                                }]
                 })
      end
    end

    %w[ thumbnail low_res high_res ].each do |type|
      image = MiniMagick::Image.open(options[:"original_#{type}"])

      case options[:filter]
      when 'grayscale'
        image.colorspace 'Gray'
      when 'sepia'
        image.sepia_tone '85%'
      end

      location = image_data.send(:"#{type}_url").split('/cliq-pic-images/').last

      bucket.wait_until_exists do
        object = bucket.object(location)

        begin
          file = Tempfile.new
          image.write(file)   # Copy the image data to our tempfile
          file.rewind         # Roll back to the beginning of the buffer

          object.upload_file(file,
                             acl: 'public-read',
                             content_type: image.mime_type)
        ensure
          file.close!
        end
      end
    end
  end
end
