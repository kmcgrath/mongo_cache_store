# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongo_cache_store/version'

Gem::Specification.new do |gem|
  gem.name          = "mongo_cache_store"
  gem.version       = MongoCacheStore::VERSION
  gem.authors       = ["Kevin McGrath"]
  gem.email         = ["kmcgrath@baknet.com"]
  gem.description   = %q{A MongoDB ActiveSupport Cache}
  gem.summary       = %q{A MongoDB ActiveSupport Cache}
  gem.homepage      = "http://kmcgrath.github.com/mongo_cache_store/"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'mongo', '~>1.8'
  gem.add_dependency 'activesupport', '>= 3'
  gem.add_development_dependency 'mocha', '~>0.13'
  gem.add_development_dependency 'rake', '~>10.0'
end
