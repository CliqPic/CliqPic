Rails.application.config.active_job.queue_adapter = :sidekiq

# Sidekiq.configure_server do |config|
#   config.redis = Redis.new({ url: 'redis://localhost:6379/0' })
# end

# Sidekiq.configure_client do |config|
#   config.redis = Redis.new({ url: 'redis://localhost:6379/0' })
# end

Sidekiq.default_worker_options = {
  unique: :until_executing,
  unique_args: ->(args) { [ args.first.except('job_id') ] }
}
