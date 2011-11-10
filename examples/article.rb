$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'redis/persistence'

Redis::Persistence.config.redis = Redis.new
# => #<Redis client v2.2.2 connected to redis://127.0.0.1:6379/0 (Redis v2.4.1)>

class Article
  include Redis::Persistence

  property :title
  property :body
  property :author, :default  => '(Unknown)'
  property :created
end

article = Article.new :id      => 1,
                      :title   => 'Do Not Blink',
                      :author  => 'Malcom Gladwell',
                      :body    => 'Imagine that I asked you ...',
                      :created => Time.now.utc
# => #<Article: {"id"=>1, "title"=>"Do Not Blink", ...>

p article.save
# => #<Article: {"id"=>1, "title"=>"Do Not Blink", ...>

p article = Article.find(1)
# => #<Article: {"id"=>1, "title"=>"Do Not Blink", ...>

p article.title
# => "Do Not Blink"

article = Article.new :id    => 2,
                      :title => 'In the Beginning Was the Command Line'
p article.save
# => #<Article: {"id"=>2, "title"=>"In the Beginning Was the Command Line", ... "author"=>"(Unknown)"}>

p article = Article.find(2)
# => #<Article: {"id"=>2, "title"=>"In the Beginning Was the Command Line", ... "author"=>"(Unknown)"}>

p article.author
# => "(Unknown)"
