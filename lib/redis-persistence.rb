require 'redis'
require 'multi_json'
require 'active_model'
require 'active_support/concern'

require 'redis-persistence/version'

class Redis
  module Persistence
    extend ActiveSupport::Concern

    included do
      include ActiveModelIntegration
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

        properties[name] = options[:default]
      end

      def properties
        @properties ||= {}
      end

      def find(id)
        self.new Yajl::Parser.parse($redis.get("#{self.to_s.pluralize.downcase}:#{id}")) rescue nil
      end

    end

    module InstanceMethods

      attr_accessor :id

      def properties
        self.class.properties.inject({}) do |attributes, key|
           attributes[key[0]] = send(key[0]) || key[1];
           attributes
        end
      end

      def to_json
        properties.to_json
      end

      def initialize(attributes={})
        properties.merge(attributes).each_pair { |name,value| instance_variable_set :"@#{name}", value }
      end

      def save
        $redis.set "#{self.class.to_s.pluralize.downcase}:#{self.id}", self.to_json
        self
      end

      def destroy
        $redis.del "#{self.class.to_s.pluralize.downcase}:#{self.id}"
        self.freeze
      end

      def persisted?
        $redis.exists "#{self.class.to_s.pluralize.downcase}:#{self.id}"
      end

      def inspect
        "#<#{self.class} : #{properties.inspect {|array, property| array << property.inspect; array }}>"
      end

    end

  end
end
