# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mirr/version'

Gem::Specification.new do |gem|
  gem.name          = "mirr"
  gem.version       = Mirr::VERSION
  gem.authors       = ["Daniel Ethridge"]
  gem.email         = ["danielethridge@icloud.com"]
  gem.license = 'GPL-3.0'

  gem.summary       = %q{Mirr - Because you like synchronization}
  gem.homepage      = "https://github.com/wlib/mirr"

  gem.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  gem.bindir        = "bin"
  gem.executables   = ["mirr"]
  gem.require_paths = ["lib"]

  gem.add_development_dependency "bundler", "~> 1.13"
  gem.add_development_dependency "rake", "~> 10.0"
  
end