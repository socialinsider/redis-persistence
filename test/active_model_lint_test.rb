require '_helper'

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
