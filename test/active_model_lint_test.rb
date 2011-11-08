require '_helper'

class PersistentArticle
  include Redis::Persistence
end

class Redis
  module Persistence

    class ActiveModelLintTest < Test::Unit::TestCase

      include ActiveModel::Lint::Tests

      def setup
        @model = PersistentArticle.new :title => 'Test'
        Redis::Persistence.config.redis = Redis.new
      end

    end

  end
end
