# =======================================================================
# Template for generating basic Rails application with Redis::Persistence
# =======================================================================
#
# Requirements
# ------------
#
# * Git
# * Ruby >= 1.9.3
# * Rubygems
# * Rails >= 3.1.0
# * Redis >= 2.4.1
#
#
# Usage
# -----
#
#     $ rails new articles -m https://raw.github.com/Ataxo/redis-persistence/master/examples/rails-template.rb
#
# ===================================================================================================================

require 'rubygems'

run "rm public/index.html"
run "rm public/images/rails.png"
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"

run "rm -f .gitignore"
file ".gitignore", <<-END.gsub(/  /, '')
  .DS_Store
  log/*.log
  tmp/**/*
  config/database.yml
  db/*.sqlite3
END

git :init
git :add => '.'
git :commit => "-m 'Initial commit: Clean application'"

puts
say_status  "Rubygems", "Adding Rubygems into Gemfile...\n", :yellow
puts        '-'*80, ''; sleep 1

gem 'redis-persistence', :git => 'git://github.com/Ataxo/redis-persistence.git'

git :add => '.'
git :commit => "-m 'Added gems'"

puts
say_status  "Rubygems", "Installing Rubygems...", :yellow
puts        '-'*80, ''

run "bundle install"

puts
say_status  "Model", "Adding the Article resource...", :yellow
puts        '-'*80, ''; sleep 1

generate :scaffold, "Article title:string content:text published:date"
route "root :to => 'articles#index'"

git :add => '.'
git :commit => "-m 'Added the Article resource'"

puts
say_status  "Model", "Adding Redis::Persistence into the Article model...", :yellow
puts        '-'*80, ''; sleep 1

run "rm -f app/models/article.rb"
file 'app/models/article.rb', <<-CODE
class Article
  include Redis::Persistence

  property :title
  property :content
  property :published
end
CODE

initializer 'redis-persistence.rb', <<-CODE
Redis::Persistence.config.redis = Redis.new(:db => 14)
CODE

git :commit => "-a -m 'Added Redis::Persistence into the Article model, added initializer (Redis DB=14)'"

puts
say_status  "Database", "Seeding the database with data...", :yellow
puts        '-'*80, ''; sleep 0.25

run "rm -rf db/migrate"
run "redis-cli -n 14 flushdb"
run "rm -f db/seeds.rb"
file 'db/seeds.rb', <<-CODE
contents = [
'Lorem ipsum dolor sit amet.',
'Consectetur adipisicing elit, sed do eiusmod tempor incididunt.',
'Labore et dolore magna aliqua.',
'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
'Excepteur sint occaecat cupidatat non proident.'
]

puts "Creating articles..."
%w[ One Two Three Four Five ].each_with_index do |title, i|
  Article.create title: title, content: contents[i], published: i.days.ago.utc
end
CODE

rake "db:seed"

git :add    => "db/seeds.rb"
git :commit => "-m 'Added database seeding script'"

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

run "git log --reverse --pretty=format:'%Cblue%h%Creset | %s'"

puts  "", "="*80
say_status  "DONE", "\e[1mStarting the application...\e[0m", :yellow
puts  "="*80, ""

run  "rails server"
