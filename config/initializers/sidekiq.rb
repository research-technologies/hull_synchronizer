# frozen_string_literal: true

config = YAML.safe_load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
# added nil https://github.com/mperham/sidekiq/wiki/Using-Redis
#redis_config = config.merge(thread_safe: true, id: nil)
redis_config = config.merge(id: nil)


Sidekiq::Logging.logger.level = Logger::WARN if ENV['RAILS_ENV'] == 'production'

Sidekiq.configure_server do |s|
  s.redis = redis_config
end

Sidekiq.configure_client do |s|
  s.redis = redis_config
end
