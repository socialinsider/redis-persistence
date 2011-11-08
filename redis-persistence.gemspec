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
end
