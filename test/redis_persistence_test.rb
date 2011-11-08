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

    should "define accessors from attributes" do
      article = PersistentArticle.new title: 'One'
      assert_equal 'One', article.title
    end

    should "set the attributes" do
      article = PersistentArticle.new title: 'One'
      article.title = 'Two'
      assert_equal 'Two', article.title
    end

    should "raise error when passing invalid attribute" do
      assert_raise NoMethodError do
        PersistentArticle.new krapulitzowka: 'Not'
      end
    end

    should "return nil for not passed attributes" do
      assert_nil PersistentArticle.new.title
    end

    should "return default values" do
      d = ModelWithDefaults.new
      assert_equal '(Unknown)', d.title
      assert_equal true, d.admin
    end

  end

  context "Class" do

    should "have properties" do
      assert_equal ['id', 'title'], PersistentArticle.properties
    end

  end

  context "Instance" do

    should "be inspectable" do
      assert_nothing_raised do
        assert_match /PersistentArticle/, PersistentArticle.new(id: 1, title: { some: { deep: 'Hash', :a => [1, 2, 3] } }).inspect
      end
    end

    should "have attributes" do
      assert_equal ['id', 'title'], PersistentArticle.new.attributes.keys
    end

    should "not persist by default" do
      assert ! PersistentArticle.new.persisted?
    end

    should "be saved and found in Redis" do
      article = PersistentArticle.new id: 1, title: 'One'
      assert article.save
      assert PersistentArticle.find(1)
      assert_equal 1, Redis::Persistence.config.redis.keys.size
      assert_equal 'One', PersistentArticle.find(1).title
    end

    should "be deleted from Redis" do
      article = PersistentArticle.new id: 1, title: 'One'
      assert article.save
      assert_not_nil PersistentArticle.find(1)
      assert_equal 1, Redis::Persistence.config.redis.keys.size

      article.destroy
      assert_nil PersistentArticle.find(1)
      assert_equal 0, Redis::Persistence.config.redis.keys.size
    end

    should "fire before_save hooks" do
      article = ModelWithCallbacks.new title: 'Hooks'
      article.expects(:my_callback_method).twice

      article.save
    end

    should "fire before_destroy hooks" do
      article = ModelWithCallbacks.new title: 'Hooks'
      article.save
      article.destroy

      assert_equal 'YEAH', article.instance_variable_get(:@hooked)
    end

  end

end
