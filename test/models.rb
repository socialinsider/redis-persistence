class PersistentArticle
  include Redis::Persistence

  property :id
  property :title
  property :created
end

class ModelWithBooleans
  include Redis::Persistence

  property :published
  property :approved
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
    attr_reader :value

    def initialize(params={})
      @value = params[:value]
    end
  end

  class Stuff
    attr_reader :values

    def initialize(values)
      @values = values
    end
  end

  include Redis::Persistence

  property :thing,   :class => Thing
  property :stuff,   :class => Stuff
end
