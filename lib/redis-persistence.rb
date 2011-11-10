require 'redis'
require 'hashr'
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

      def create(attributes={})
        new(attributes).save
      end

      def property(name, options = {})
        attr_accessor name.to_sym
        properties << name.to_s unless properties.include?(name.to_s)

        property_defaults[name.to_sym] = options[:default] if options[:default]
        property_types[name.to_sym]    = options[:class]   if options[:class]
        unless options[:family]
          (property_families[:data] ||= [])                   << name.to_s
        else
          (property_families[options[:family].to_sym] ||= []) << name.to_s
        end
        self
      end

      def properties
        @properties ||= ['id']
      end

      def property_defaults
        @property_defaults ||= {}
      end

      def property_types
        @property_types ||= {}
      end

      def property_families
        @property_families ||= { :data => ['id'] }
      end

      def find(id, options={})
        families = ['data'] | Array(options[:families])
        data = __redis.hmget("#{self.model_name.plural}:#{id}", *families)

        unless data.compact.empty?
          attributes = data.inject({}) { |hash, item| hash.update( MultiJson.decode(item) ); hash }
          self.new attributes
        end
      end

      def __next_id
        __redis.incr("#{self.model_name.plural}:__ids__")
      end

    end

    module InstanceMethods
      attr_accessor :id

      def initialize(attributes={})
        self.class.property_defaults.merge(attributes).each do |name, value|
          case
          when klass = self.class.property_types[name.to_sym]
            send "#{name}=", klass.new(value)
          when value.is_a?(Hash)
            send "#{name}=", Hashr.new(value)
          else
            send "#{name}=", value
          end
        end
        self
      end
      alias :attributes= :initialize

      def attributes
        self.class.
          properties.
          inject({}) {|attributes, key| attributes[key] = send(key); attributes}
      end

      def save
        run_callbacks :save do
          self.id ||= self.class.__next_id
          params    = self.class.property_families.keys.map do |family|
                        [family.to_s, self.to_json(:only => self.class.property_families[family])]
                      end.flatten
          __redis.hmset "#{self.class.model_name.plural}:#{self.id}", *params
        end
        self
      end

      def destroy
        run_callbacks :destroy do
          __redis.del "#{self.class.model_name.plural}:#{self.id}"
        end
        self.freeze
      end

      def persisted?
        __redis.exists "#{self.class.model_name.plural}:#{self.id}"
      end

      def inspect
        "#<#{self.class}: #{attributes}>"
      end

    end

  end
end
