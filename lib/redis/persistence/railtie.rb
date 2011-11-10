require 'rails/generators/redis_persistence'

module RedisPersistence
  class Railtie < Rails::Railtie
    # Automatically configure ORM for Rails generators
    #
    # config.app_generators.orm :redis_persistence
  end
end
