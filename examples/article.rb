$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'redis/persistence'
require 'active_support/core_ext/hash/indifferent_access'

Redis::Persistence.config.redis = Redis.new :db => 14
Redis::Persistence.config.redis.flushdb
# => #<Redis client v2.2.2 connected to redis://127.0.0.1:6379/0 (Redis v2.4.1)>

class Comment
  def initialize(params);                      @attributes = HashWithIndifferentAccess.new(params); end
  def method_missing(method_name, *arguments); @attributes[method_name];                            end
  def as_json(*);                              @attributes;                                         end
end

class Article
  include Redis::Persistence

  property :title
  property :body
  property :author, :default  => '(Unknown)'
  property :created

  property :comments, :default => [], :class => [Comment], :family => 'comments'
end

article = Article.new :title   => 'Do Not Blink',
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

p article.created.year
# => 2011

article = Article.new :title => 'In the Beginning Was the Command Line'
p article.save
# => #<Article: {"id"=>2, "title"=>"In the Beginning Was the Command Line", ... "author"=>"(Unknown)"}>

p article = Article.find(2)
# => #<Article: {"id"=>2, "title"=>"In the Beginning Was the Command Line", ... "author"=>"(Unknown)"}>

p article.author
# => "(Unknown)"

article = Article.create :title => 'OMG BLOG!'

p article.comments
# => []

article.comments << {:nick => '4chan', :body => 'WHY U NO QUIT?'}

article.comments << Comment.new(:nick => 'h4x0r', :body => 'WHY U NO USE BBS?')

p article.comments.size
# => 2

p article.save(families: 'comments')
# => <Article: {"id"=>3, ... "comments"=>[{:nick=>"4chan", :body=>"WHY U NO QUIT?"}]}>

article = Article.find(3)
p article.comments
# => []

article = Article.find(3, :families => 'comments')
p article.comments
# => [#<Comment @attributes={"nick"=>"4chan", "body"=>"WHY U NO QUIT?"}>, ...]

p article.comments.first.nick
# => "4chan"

p article.comments.last.nick
# => "h4x0r"
