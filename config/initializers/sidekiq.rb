Rails.application.config.active_job.queue_adapter = :sidekiq
ActiveRecord::Base.logger = Logger.new(STDOUT)  
Sidekiq.configure_server do |config|
  config.redis = { driver: 'hiredis' }

  # Setup some hostfile shit so that we can send emails
  %x[ line=$(head -n 1 /etc/hosts);
      line2=$(echo $line | aws '{ print $2 }');
      echo "$line $line2.localdomain" >> /etc/hosts
    ]
end

Sidekiq.configure_client do |config|
  config.redis = { driver: 'hiredis' }
end

Sidekiq.default_worker_options = {
  unique: :until_executing,
  unique_args: ->(args) { [ args.first.except('job_id') ] }
}
