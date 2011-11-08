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
