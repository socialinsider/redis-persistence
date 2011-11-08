require 'redis'
require 'multi_json'
require 'active_model'
require 'active_support/concern'
require 'active_support/configurable'

require 'redis-persistence/version'

class Redis
  module Persistence
    include ActiveSupport::Configurable
    extend  ActiveSupport::Concern

    included do
      include ActiveModelIntegration
      self.include_root_in_json = false

      def self.__redis
        Redis::Persistence.config.redis
      end

      def __redis
        self.class.__redis
      end
    end

    module ActiveModelIntegration
      extend ActiveSupport::Concern

      included do
        include ActiveModel::AttributeMethods
        include ActiveModel::Validations
        include ActiveModel::Serialization
        include ActiveModel::Serializers::JSON
        include ActiveModel::Naming
        include ActiveModel::Conversion

        extend  ActiveModel::Callbacks
        define_model_callbacks :save, :destroy
      end
    end

    module ClassMethods

      def property(name, options = {})
        attr_accessor name.to_sym
        properties << name.to_s unless properties.include?(name.to_s)
        define_attribute_methods [name.to_sym]
        send name.to_s, options[:default] if options[:default]
        self
      end

      def properties
        @properties ||= []
      end

      def find(id)
        self.new.from_json(__redis.get("#{self.to_s.pluralize.downcase}:#{id}"))
      end

    end

    module InstanceMethods

      attr_accessor :id

      def initialize(attributes={})
        attributes.each { |name, value| send("#{name}=", value) }
        self
      end
      alias :attributes= :initialize

      def attributes
        self.class.properties.
          inject( self.id ? {'id' => self.id} : {} ) {|attributes, key| attributes[key] = send(key); attributes}
      end

      def save
        __redis.set "#{self.class.to_s.pluralize.downcase}:#{self.id}", self.to_json
        self
      end

      def destroy
        __redis.del "#{self.class.to_s.pluralize.downcase}:#{self.id}"
        self.freeze
      end

      def persisted?
        __redis.exists "#{self.class.to_s.pluralize.downcase}:#{self.id}"
      end

      def inspect
        "#<#{self.class} : #{attributes.inspect {|array, property| array << property.inspect; array }}>"
      end

    end

  end
end
