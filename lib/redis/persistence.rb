require 'redis'
require 'hashr'
require 'multi_json'
require 'active_model'
require 'active_support/concern'
require 'active_support/configurable'

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

      def find(args, options={})
        args.is_a?(Array) ? __find_many(args, options) : __find_one(args, options)
      end

      def __find_one(id, options={})
        families = ['data'] | Array(options[:families])
        data = __redis.hmget("#{self.model_name.plural}:#{id}", *families)

        unless data.compact.empty?
          attributes = data.inject({}) { |hash, item| hash.update( MultiJson.decode(item) ); hash }
          self.new attributes
        end
      end

      def __find_all(options={})
        ids = __redis.keys("#{self.model_name.plural}:*").map { |id| id[/:(\d+)$/, 1] }.sort
        __find_many ids
      end
      alias :all :__find_all

      def __find_many(ids, options={})
        ids.map { |id| __find_one(id, options) }.compact
      end

      def __next_id
        __redis.incr("#{self.model_name.plural}_ids")
      end

    end

    module InstanceMethods
      attr_accessor :id

      def initialize(attributes={})
        __update_attributes self.class.property_defaults.merge(attributes)
        self
      end
      alias :attributes= :initialize

      def update_attributes(attributes={})
        __update_attributes attributes
        save
        self
      end

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

      def __update_attributes(attributes)
        attributes.each do |name, value|
          case
          when klass = self.class.property_types[name.to_sym]
            if klass.is_a?(Array) && value.is_a?(Array)
              send "#{name}=", value.map { |v| klass.first.new(v) }
            else
              send "#{name}=", klass.new(value)
            end
          when value.is_a?(Hash)
            send "#{name}=", Hashr.new(value)
          else
            # Automatically convert <http://en.wikipedia.org/wiki/ISO8601> formatted strings to Time
            value = Time.parse(value) if value.is_a?(String) && value =~ /^\d{4}[\/\-]\d{2}[\/\-]\d{2}T\d{2}\:\d{2}\:\d{2}Z$/
            send "#{name}=", value
          end
        end
      end

    end

  end
end
