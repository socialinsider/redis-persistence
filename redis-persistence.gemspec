# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis-persistence/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Karel Minarik", "Vojtech Hyza"]
  gem.email         = ["karmi@karmi.cz", "vhyza@vhyza.eu"]
  gem.description   = %q{Simple ActiveModel compatible persistence layer}
  gem.summary       = %q{Simple ActiveModel compatible persistence layer}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "redis-persistence"
  gem.require_paths = ["lib"]
  gem.version       = Redis::Persistence::VERSION

  # = Library dependencies
  #
  gem.add_dependency "activemodel", "~> 3.0"
  gem.add_dependency "multi_json",  "~> 1.0"

  # = Development dependencies
  #
  gem.add_development_dependency "bundler",     "~> 1.0.0"
  gem.add_development_dependency "yajl-ruby",   "~> 0.8.0"
  gem.add_development_dependency "shoulda"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "turn"
end
