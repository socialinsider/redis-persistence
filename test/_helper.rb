require 'test/unit'
require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"] || ENV["CI"]
require 'mocha'

require 'redis-persistence'

