# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hazetug/version'

Gem::Specification.new do |spec|
  spec.name          = "hazetug"
  spec.version       = Hazetug::VERSION
  spec.authors       = ["Denis Barishev"]
  spec.email         = ["dennybaa@gmail.com"]
  spec.summary       = %q{Cloud provisoner tool}
  spec.description   = %q{Provisions and bootstraps nodes using knife}
  spec.homepage      = "https://github.com/dennybaa/hazetug"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 0"
  spec.add_dependency "psych", "~> 0"
  spec.add_dependency "fog", "~> 0"
  spec.add_dependency "chef", "~> 11.0"
  spec.add_dependency "gli",  "~> 2.0"
  spec.add_dependency "agent", "~> 0"
  spec.add_dependency "berkshelf", "~> 3.0"
end
