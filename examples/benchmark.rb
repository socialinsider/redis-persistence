$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'sqlite3'

require 'benchmark'
require 'redis/persistence'
require 'active_support/core_ext/hash/indifferent_access'

content = DATA.read
COUNT   = (ENV['COUNT'] || 100_000).to_i

Redis::Persistence.config.redis = Redis.new :db => 14
Redis::Persistence.config.redis.flushdb

DATABASE_FILE = '/tmp/tire_benchmark_articles.sqlite3'
File.delete DATABASE_FILE rescue nil
# ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )
ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => DATABASE_FILE )
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :sql_articles do |t|
    t.string     :title
    t.text       :content
    t.timestamps
  end
end

class Article
  include Redis::Persistence

  property :title
  property :content, :family => 'extra'
  property :created, :family => 'extra'
end

class SQLArticle < ActiveRecord::Base
end

puts "Beginning the benchmark script (SQLite and Redis)...", "", '='*80
sleep 5

puts "Saving #{COUNT} records into a SQLite database..."

elapsed = Benchmark.realtime do
  (1..COUNT).map do |i|
    SQLArticle.create title: "Document #{i}", content: content
  end
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
     '-'*80

puts "Finding all records from SQLite..."

elapsed = Benchmark.realtime do
  SQLArticle.all
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
     '-'*80

puts "Finding #{COUNT} records one by one from SQLite..."

elapsed = Benchmark.realtime do
 (1..COUNT).map { |i| SQLArticle.find(i) }
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
     '-'*80

puts "Updating all documents in batches of 1000 in SQLite..."

elapsed = Benchmark.realtime do
  SQLArticle.find_each { |document| document.title += ' (touched)' and document.save }
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec"

puts "", '='*80, ""
sleep 5

puts "Saving #{COUNT} documents into Redis..."

elapsed = Benchmark.realtime do
  (1..COUNT).map do |i|
    Article.create title: "Document #{i}", content: content, created: Time.now.utc
  end
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
     '-'*80

puts "Finding all documents..."

elapsed = Benchmark.realtime do
  Article.all
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
    '-'*80

puts "Finding #{COUNT} documents one by one..."

elapsed = Benchmark.realtime do
  (1..COUNT).map do |i|
    Article.find(i, :family => 'extra')
  end
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec",
     '-'*80

puts "Finding first 1000 documents with only 'default' family..."

elapsed = Benchmark.realtime do
  Article.find (1..1000).to_a
end

puts "Duration: #{elapsed*1000} milliseconds, rate: #{1000.0/elapsed} docs/sec, #{(elapsed/1000.0)*1000.0} msec/doc",
     '-'*80

puts "Updating all documents in batches of 1000..."

elapsed = Benchmark.realtime do
  Article.find_each { |document| document.title += ' (touched)' and document.save }
end

puts "Duration: #{elapsed} seconds, rate: #{COUNT.to_f/elapsed} docs/sec"

puts '='*80

__END__
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
