require 'rails/generators/named_base'
require 'rails/generators/active_model'

module RedisPersistence
  module Generators

    class ActiveModel < ::Rails::Generators::ActiveModel
      def self.all(klass)
        "#{klass}.all"
      end

      def self.find(klass, params=nil)
        "#{klass}.find(#{params})"
      end

      def self.build(klass, params=nil)
        if params
          "#{klass}.new(#{params})"
        else
          "#{klass}.new"
        end
      end

      def save
        "#{name}.save"
      end

      def update_attributes(params=nil)
        "#{name}.update_attributes(#{params})"
      end

      def errors
        "#{name}.errors"
      end

      def destroy
        "#{name}.destroy"
      end
    end

  end
end
