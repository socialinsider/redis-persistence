class Piece
  def initialize(params)
    @attributes = HashWithIndifferentAccess.new(params)
  end

  def method_missing(method_name, *arguments)
    @attributes[method_name]
  end

  def as_json(*)
    @attributes
  end
end

class PersistentArticle
  include Redis::Persistence

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
  before_create  :my_before_create_method

  property :title

  def my_callback_method
  end

  def my_before_create_method
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
      @value = params[:value] || params['value']
    end
  end

  class Stuff
    attr_reader :values

    def initialize(values)
      @values = values
    end

    def as_json(*)
      values
    end
  end

  include Redis::Persistence

  property :thing,  :class => Thing
  property :stuff,  :class => Stuff,   :default => []
  property :pieces, :class => [Piece], :default => []
end

class ModelWithDeepHashes
  include Redis::Persistence

  property :tree
end

class ModelWithFamily
  include Redis::Persistence

  property :name

  property :views,  :family  => 'counters'
  property :visits, :family  => 'counters'
  property :tags,   :family  => 'tags', :default => []

  property :lang,   :family  => 'meta'
end

class ModelWithCastingInFamily
  include Redis::Persistence
  property :pieces, :class => [Piece], :default => [], :family => 'meta'
  property :parts,  :class => [Piece], :default => [], :family => 'other'
end

class ModelWithDefaultArray
  include Redis::Persistence

  property :accounts, :default => []
  property :options,  :default => { :switches => []}
  property :deep,     :default => { :one => { :two => { :three => [] } } }
end

class ModelWithDefaultsInFamilies
  include Redis::Persistence

  property :name
  property :tags, :default => [], :family => 'tags'
end

class ModelWithDefaultLambdas
  include Redis::Persistence

  property :name
  property :created_at, :default => lambda { Time.now }
end
