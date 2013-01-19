# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'berkshelf-shims/version'

Gem::Specification.new do |gem|
  gem.name          = "berkshelf-shims"
  gem.version       = WP::Cookbook::VERSION
  gem.authors       = ["Jeff Bellegarde"]
  gem.email         = ["bellegar@gmail.com"]
  gem.description   = %q{Shim functionality for Berkshelf}
  gem.summary       = %q{Provides methods to create a cookbooks directory derived from  Berksfile.lock.}
  gem.homepage      = "https://github.com/JeffBellegarde/berkshelf-shims"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

end
