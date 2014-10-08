require 'bundler/setup'

require 'minitest/autorun'
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'shoulda'
require 'mocha/setup'

require 'active_support/core_ext/hash/indifferent_access'

require 'redis/persistence'
require 'yajl'

require 'models'

Redis::Persistence.config.redis = Redis.new db: ENV['REDIS_PERSISTENCE_TEST_DATABASE'] || 14

class ActiveSupport::TestCase
  def setup    ; Redis::Persistence.config.redis.flushdb ; end
  def teardown ; Redis::Persistence.config.redis.flushdb ; end
end

class Minitest::Unit::TestCase
  def setup    ; Redis::Persistence.config.redis.flushdb ; end
  def teardown ; Redis::Persistence.config.redis.flushdb ; end
end
