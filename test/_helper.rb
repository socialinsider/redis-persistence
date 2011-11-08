require 'test/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"] || ENV["CI"]
require 'mocha'

require 'redis-persistence'

$redis = Redis.new :url => ENV["REDIS_URL_TEST"] || 'redis://127.0.0.1:6379/14'
