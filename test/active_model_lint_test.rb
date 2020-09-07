require '_helper'

class Redis
  module Persistence

    class ActiveModelLintTest < MiniTest::Unit::TestCase

      include ActiveModel::Lint::Tests

      def setup
        super
        @model = PersistentArticle.new title: 'Test'
      end

    end

  end
end
