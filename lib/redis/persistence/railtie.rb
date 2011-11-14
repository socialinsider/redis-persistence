module RedisPersistence
  class Railtie < Rails::Railtie

    initializer "warn when configuration is missing" do
      config.after_initialize do
        unless ::Redis::Persistence.config.redis
          puts "\n[ERROR!] Redis::Persistence is not configured!", '='*80,
               "Please point `Redis::Persistence.config.redis` to a Redis instance, ",
               "if you actually intend to save some data :)\n\n",
               "You can create an initializer with:\n\n",
               "    $ rails generate redis_persistence:initializer\n\n", '-'*80, "\n"
        end
      end
    end

  end
end
