module RedisPersistence
  module Generators

    class InitializerGenerator < Rails::Generators::Base

      desc "Creates initializer file for redis-persistence in config/initializers."
      argument :database, :type => :string, :default => '14', :optional => true, :banner => "<REDIS DATABASE NUMBER>"

      source_root File.expand_path("../templates", __FILE__)

      def create_initializer_file
        template "initializer.rb.tt", "config/initializers/redis-persistence.rb"
      end

    end

  end
end
