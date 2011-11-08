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

class ModelWithCasting

  class Thing
  end

  include Redis::Persistence

  property :thing,  :class => Thing
  property :things, :class => [Thing]

  property :created, :class => Time
end
