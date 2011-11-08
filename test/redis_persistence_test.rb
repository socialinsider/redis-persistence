require '_helper'

class RedisPersistenceTest < ActiveSupport::TestCase
  def setup;    super; end
  def teardown; super; end

  context "Redis Connection" do
  
    should "be set" do
      assert_nothing_raised { Redis::Persistence.config.redis.info }
    end
  
  end
  
  context "Defining properties" do
  
  end

  context "Instance" do

    should "not persist by default" do
      assert ! PersistentArticle.new.persisted?
    end

    should "be saved and found in Redis" do
      article = PersistentArticle.new id: 1, title: 'One'
      assert article.save
      assert PersistentArticle.find(1)
      assert_equal 'One', PersistentArticle.find(1).title
    end

  end

end
