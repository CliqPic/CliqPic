Rails.application.config.active_job.queue_adapter = :sidekiq

Sidekiq.configure_server do |config|
  config.redis = { driver: 'hiredis' }
end

Sidekiq.configure_client do |config|
  config.redis = { driver: 'hiredis' }
end

Sidekiq.default_worker_options = {
  unique: :until_executing,
  unique_args: ->(args) { [ args.first.except('job_id') ] }
}
