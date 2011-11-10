require '_helper'

class RedisPersistenceTest < ActiveSupport::TestCase
  def setup;    super; end
  def teardown; super; end

  def in_redis
    Redis::Persistence.config.redis
  end

  context "Redis Connection" do
  
    should "be set" do
      assert_nothing_raised { in_redis.info }
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

    should "return time as time" do
      a = PersistentArticle.new created: Time.new(2011, 11, 9).utc
      assert_instance_of Time, a.created
    end

    should "return boolean as boolean" do
      m = ModelWithBooleans.new published: false, approved: true
      assert_instance_of FalseClass, m.published
      assert_instance_of TrueClass,  m.approved
    end

    should "cast the value" do
      m = ModelWithCasting.new thing: { :value => 1 }, stuff: [1, 2, 3]

      assert_instance_of ModelWithCasting::Thing, m.thing
      assert_instance_of ModelWithCasting::Stuff, m.stuff

      assert_equal 1, m.thing.value
      assert_equal 1, m.stuff.values.first
    end

    should "provide easy access to deep hashes" do
      m = ModelWithDeepHashes.new tree: { trunk: { branch: 'leaf' } }
      assert_equal 'leaf', m.tree.trunk.branch
    end

  end

  context "Defining properties in families" do

    should "store properties in the 'data' family by default" do
      m = ModelWithFamily.new name: 'One'
      m.save

      assert in_redis.exists('model_with_families:1'), in_redis.keys.to_s
      assert in_redis.hkeys('model_with_families:1').include?('data')
    end

    should "store properties in the correct family" do
      m = ModelWithFamily.new name: 'F', views: 100, visits: 10, lang: 'en'
      m.save

      assert_equal 1, m.id
      assert in_redis.exists('model_with_families:1'), in_redis.keys.to_s
      assert in_redis.hkeys('model_with_families:1').include?('data'),     in_redis.hkeys('model_with_families:1').to_s
      assert in_redis.hkeys('model_with_families:1').include?('counters'), in_redis.hkeys('model_with_families:1').to_s

      m = ModelWithFamily.find(1)
      assert_not_nil m.name
      assert_nil     m.views

      m = ModelWithFamily.find(1, :families => ['counters', 'meta'])
      assert_not_nil m.name
      assert_not_nil m.views

      assert_equal 'F',  m.name
      assert_equal 10,   m.visits
      assert_equal 'en', m.lang
    end

  end

  context "Class" do

    should "have properties" do
      assert_equal ['id', 'title', 'created'], PersistentArticle.properties
    end

    should "have auto-incrementing counter" do
      assert_equal 1, PersistentArticle.__next_id
      assert_equal 2, PersistentArticle.__next_id
    end

    should "create new instance" do
      a = PersistentArticle.create title: 'One'
      assert          a.persisted?
      assert_equal 1, a.id
      assert in_redis.keys.size > 0, 'Key not saved into Redis?'
    end

  end

  context "Instance" do

    should "be inspectable" do
      assert_nothing_raised do
        assert_match /PersistentArticle/, PersistentArticle.new(id: 1, title: { some: { deep: 'Hash', :a => [1, 2, 3] } }).inspect
      end
    end

    should "have attributes" do
      assert_equal ['id', 'title', 'created'], PersistentArticle.new.attributes.keys
    end

    should "not persist by default" do
      assert ! PersistentArticle.new.persisted?
    end

    should "be saved and found in Redis" do
      article = PersistentArticle.new id: 1, title: 'One'
      assert article.save
      assert in_redis.exists("persistent_articles:1")

      assert PersistentArticle.find(1)
      assert in_redis.keys.size > 0, 'Key not saved into Redis?'
      assert_equal 'One', PersistentArticle.find(1).title
    end

    should "be deleted from Redis" do
      article = PersistentArticle.new id: 1, title: 'One'
      assert article.save
      assert_not_nil PersistentArticle.find(1)
      assert in_redis.keys.size > 0, 'Key not saved into Redis?'

      article.destroy
      assert_nil PersistentArticle.find(1)
      assert_equal 0, in_redis.keys.size, 'Key not removed from Redis?'
    end

    should "update attributes" do
      a = PersistentArticle.new title: 'Old'
      a.save

      assert a.update_attributes title: 'New'

      a = PersistentArticle.find(1)
      assert_equal 'New', a.title
    end

    should "get auto-incrementing ID on save when none is passed" do
      article = PersistentArticle.new title: 'One'

      assert_nil article.id

      assert article.save
      assert_not_nil article.id

      assert_equal 1, PersistentArticle.find(1).id
      assert_equal 2, PersistentArticle.__next_id
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

    should "perform validations" do
      m = ModelWithValidations.new

      assert ! m.valid?
      assert_equal 1, m.errors.to_a.size
    end

  end

end
