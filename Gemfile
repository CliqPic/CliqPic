source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

gem 'insta_scrape'

gem 'ruby-instagram-scraper', github: "amdirent/ruby-instagram-scraper"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# For interacting with the Instagram API
gem 'instagram', '~> 1.1', '>= 1.1.6'

# Devise for user management
gem 'devise', '~> 4.2'
gem 'omniauth', '~> 1.3', '>= 1.3.1'
gem 'omniauth-instagram', '~> 1.0', '>= 1.0.2'

# Background Jobs
gem 'hiredis', '~> 0.6.1'
gem 'sidekiq', '~> 4.2', '>= 4.2.10'
gem 'sidekiq-unique-jobs', '~> 4.0', '>= 4.0.18'

# For geocoding and distance calculations
gem 'geokit', '~> 1.11'

# Image manipulation
gem 'mini_magick', '~> 4.7.0'

# AWS interaction
gem 'aws-sdk', '~> 2.9.11'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :test do
  gem 'rspec-sidekiq'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'rspec-rails'
  gem 'dotenv-rails'
end

group :development do
  gem 'letter_opener'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring-commands-rspec'
  gem 'pry'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'
