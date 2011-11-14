module RedisPersistence
  module Generators

    class ModelGenerator < Rails::Generators::NamedBase

      desc "Creates a Redis::Persistence-based model."
      argument :attributes, :type => :array, :default => [], :banner => "property:type property:type ..."

      source_root File.expand_path("../templates", __FILE__)

      check_class_collision

      def create_model_file
        template "model.rb.tt", File.join("app/models", "#{file_name}.rb")
      end

      hook_for :test_framework

      def module_namespacing(&block)
        yield if block
      end unless methods.include?(:module_namespacing)

    end

  end
end
