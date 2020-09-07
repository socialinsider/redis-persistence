require 'bundler/setup'

require 'minitest/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"] || ENV["CI"]
require 'mocha/minitest'

require 'active_support/core_ext/hash/indifferent_access'

require 'redis/persistence'
require 'yajl'

require 'models'

class Minitest::Test

  def setup
    Redis::Persistence.config.redis = Redis.new db: ENV['REDIS_PERSISTENCE_TEST_DATABASE'] || 14
    Redis::Persistence.config.redis.flushdb
  end

  def teardown
    Redis::Persistence.config.redis.flushdb
    Redis::Persistence.configure do |config|
      config.redis = nil
    end
  end

end
