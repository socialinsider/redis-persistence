require 'test/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"] || ENV["CI"]
require 'mocha'

require 'redis-persistence'
require 'yajl'

class PersistentArticle
  include Redis::Persistence

  property :id
  property :title
end

class Test::Unit::TestCase

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
