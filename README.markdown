Redis Persistence
=================

`Redis::Persistence` is a simple persistence layer for Ruby objects, fully compatible with ActiveModel,
and thus easily used both standalone or in a Rails project.

## Usage ##

```ruby
require 'redis/persistence'

Redis::Persistence.config.redis = Redis.new
# => #<Redis client v2.2.2 connected to redis://127.0.0.1:6379/0 (Redis v2.4.1)>

class Article
  include Redis::Persistence

  property :id
  property :title
  property :body
  property :author, :default => '(Unknown)'
end

article = Article.new :id => 1, :title => 'Lorem Ipsum'
# => #<Article: {"id"=>1, "title"=>"Lorem Ipsum", "body"=>nil, "author"=>"(Unknown)"}>

article.save
# => #<Article: {"id"=>1, "title"=>"Lorem Ipsum", "body"=>nil, "author"=>"(Unknown)"}>

article = Article.find(1)
# => #<Article: {"id"=>1, "title"=>"Lorem Ipsum", "body"=>nil, "author"=>"(Unknown)"}>

article.title
# => "Lorem Ipsum"

article.author
# => "(Unknown)"
```

It comes with the standard feature set of ActiveModel classes: validations, callbacks, serialization,
Rails DOM helpers compatibility, etc.


## Installation ##

    git clone git://github.com/Ataxo/redis-persistence.git
    rake install

-----

(c) 2011, Ataxo Interactive, s.r.o., released under the MIT License.
