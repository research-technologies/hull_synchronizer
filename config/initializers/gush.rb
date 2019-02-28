# config/initializers/gush.rb
# Gush::Worker.class_eval do
#   rescue_from(StandardError) do |e|
#     # Any handling you want to do e.g. report to Sentry/Rollbar/etc
#     Could we stop it from going in for a retry in sidekiq here
#   end
# end

Gush.configure do |config|
  config.redis_url = "redis://#{ENV.fetch('REDIS_HOST', 'localhost')}:#{ENV.fetch('REDIS_PORT', '6379')}"
  config.concurrency = 1
  # config.ttl = 3600*24*7
end
