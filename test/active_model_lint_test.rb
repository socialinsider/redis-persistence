require '_helper'

class PersistentArticle
  include Redis::Persistence
end

class Redis
  module Persistence

    class ActiveModelLintTest < Test::Unit::TestCase

      include ActiveModel::Lint::Tests

      def setup
        super
        @model = PersistentArticle.new title: 'Test'
      end

    end

  end
end
