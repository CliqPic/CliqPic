# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
#if Rails.env.production?
#  raise "No path found" if Dir.entries("#{Rails.root}/public/assets/").select { |i| i.match("sprockets") }.first.nil?
#  Rails.application.config.assets.manifest = "#{Rails.root}/public/assets/#{Dir.entries("#{Rails.root}/public/assets/").select { |i| i.match("sprockets") }.first}"
#end