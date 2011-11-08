class PersistentArticle
  include Redis::Persistence

  property :id
  property :title
end

class ModelWithDefaults
  include Redis::Persistence

  property :title, default: '(Unknown)'
  property :admin, default: true
end

class ModelWithCallbacks
  include Redis::Persistence

  before_save    :my_callback_method
  after_save     :my_callback_method
  before_destroy { @hooked = 'YEAH' }

  property :title

  def my_callback_method
  end
end

class ModelWithValidations
  include Redis::Persistence

  property :title

  validates_presence_of :title
end
