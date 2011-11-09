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
        property_defaults[name.to_sym] = options[:default] if options[:default]
        property_types[name.to_sym]    = options[:class]   if options[:class]
        self
      end

      def properties
        @properties ||= []
      end

      def property_defaults
        @property_defaults ||= {}
      end

      def property_types
        @property_types ||= {}
      end

      def find(id)
        if json = __redis.get("#{self.to_s.pluralize.downcase}:#{id}")
          self.new.from_json(json)
        end
      end

    end

    module InstanceMethods

      attr_accessor :id

      def initialize(attributes={})
        self.class.property_defaults.merge(attributes).each do |name, value|
          if klass = self.class.property_types[name.to_sym]
            send "#{name}=", klass.new(value)
          else
            send "#{name}=", value
          end
        end
        self
      end
      alias :attributes= :initialize

      def attributes
        self.class.properties.
          inject( self.id ? {'id' => self.id} : {} ) {|attributes, key| attributes[key] = send(key); attributes}
      end

      def save
        run_callbacks :save do
          __redis.set "#{self.class.to_s.pluralize.downcase}:#{self.id}", self.to_json
        end
        self
      end

      def destroy
        run_callbacks :destroy do
          __redis.del "#{self.class.to_s.pluralize.downcase}:#{self.id}"
        end
        self.freeze
      end

      def persisted?
        __redis.exists "#{self.class.to_s.pluralize.downcase}:#{self.id}"
      end

      def inspect
        "#<#{self.class}: #{attributes}>"
      end

    end

  end
end
