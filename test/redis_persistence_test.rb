require '_helper'

class PersistentArticle
  include Redis::Persistence
end

class RedisPersistenceTest < ActiveSupport::TestCase

  setup do
    Redis::Persistence.config.redis = Redis.new
  end

  context "Redis Connection" do

    should "be set" do
      assert_nothing_raised { Redis::Persistence.config.redis.info }
    end

  end

  context "Defining properties" do

    should "" do
    end

  end

  context "Instance" do

    should "not persist by default" do
      assert ! PersistentArticle.new.persisted?
    end

  end

  context "Finding records" do
  end

end
