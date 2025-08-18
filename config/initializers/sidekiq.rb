# Sidekiq configuration for optimal performance
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Concurrency settings for the suggest queue
  config.queues = [ "default", "suggest" ]
  config.concurrency = 10

  # Fast job processing for low latency
  config.average_scheduled_poll_interval = 2

  # TODO: Add error handlers for production
  # config.error_handlers << Proc.new { |ex, ctx| ... }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

# Performance optimizations for real-time processing
Sidekiq.default_job_options = {
  "retry" => 1,
  "queue" => "default"
}

# TODO: Add Sidekiq Pro features for better queue management
# TODO: Configure Sidekiq monitoring dashboard
