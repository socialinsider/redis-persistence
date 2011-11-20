require 'redis'
require 'hashr'
require 'multi_json'
require 'active_model'
require 'active_support/concern'
require 'active_support/configurable'

require File.expand_path('../persistence/railtie', __FILE__) if defined?(Rails)

class Redis
  module Persistence
    extend  ActiveSupport::Concern

    class RedisNotAvailable < StandardError; end

    DEFAULT_FAMILY = 'default'

    def self.config
      @__config ||= Hashr.new
    end

    def self.configure
      yield config
    end

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
        attr_reader name.to_sym

        define_method("#{name}=") do |value|
          # When changing property, update also loaded family
          # TODO: Research ActiveModel's dirty
          self.__loaded_families |= self.class.property_families.invert.map do |key, value|
                                      value.to_s if key.map(&:to_s).include?(name.to_s)
                                    end.compact if \
                                    (instance_variable_get(:"@#{name}") != value && self.class.property_defaults[name.to_sym] != value)
          # Store the value in instance variable
          instance_variable_set(:"@#{name}", value)
        end

        properties << name.to_s unless properties.include?(name.to_s)
        property_defaults[name.to_sym] = options[:default] if options[:default]
        property_types[name.to_sym]    = options[:class]   if options[:class]
        unless options[:family]
          (property_families[DEFAULT_FAMILY.to_sym] ||= [])   << name.to_s
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
        @property_families ||= { DEFAULT_FAMILY.to_sym => ['id'] }
      end

      def find(args, options={})
        args.is_a?(Array) ? __find_many(args, options) : __find_one(args, options)
      end

      def __find_one(id, options={})
        families = [DEFAULT_FAMILY.to_s] | Array(options[:families])
        data = __redis.hmget("#{self.model_name.plural}:#{id}", *families)

        unless data.compact.empty?
          attributes = data.compact.inject({}) { |hash, item| hash.update( MultiJson.decode(item, :symbolize_keys => true) ); hash }
          instance   = self.new attributes
          instance.__loaded_families = families
          instance
        end
      end

      def __find_all(options={})
        __find_many __all_ids
      end
      alias :all :__find_all

      def __find_many(ids, options={})
        ids.map { |id| __find_one(id, options) }.compact
      end

      def find_each(options={}, &block)
        batch_size = options.delete(:batch_size) || 1000
        __all_ids.each_slice batch_size do |batch|
          __find_many(batch, options).each { |document| yield document }
        end
      end

      def __next_id
        __redis.incr("#{self.model_name.plural}_ids")
      end

      def __all_ids
        __redis.keys("#{self.model_name.plural}:*").map { |id| id[/:(.+)$/, 1] }.sort
      end

    end

    module InstanceMethods
      attr_accessor :id
      attr_writer   :__loaded_families

      def initialize(attributes={})
      self.class.property_families.each do |name, properties|
        # Store "loaded_families" based on passed attributes, for using on save 
        self.__loaded_families |= [name.to_s] if ( properties.map(&:to_s) & attributes.keys.map(&:to_s) ).size > 0
      end
        # Make copy of objects in the property defaults hash
        property_defaults = self.class.property_defaults.inject({}) do |sum, item|
          key, value = item
          sum[key] = value.class.respond_to?(:new) ? value.clone : value
          sum
        end

        __update_attributes property_defaults.merge(attributes)
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

      def save(options={})
        run_callbacks :save do
          self.id ||= self.class.__next_id
          families  = options[:families] == 'all' ? self.class.property_families.keys : self.__loaded_families
          params    = families.map do |family|
                        [family.to_s, self.to_json(:only => self.class.property_families[family.to_sym])]
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

      def __loaded_families
        @__loaded_families ||= [DEFAULT_FAMILY.to_s]
      end

    end

  end
end
