# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pioneer600/version'

Gem::Specification.new do |spec|
  spec.name          = "pioneer600"
  spec.version       = Pioneer600::VERSION
  spec.authors       = ["Askar Zinurov"]
  spec.email         = ["askar.zinurov@flatstack.com"]

  spec.summary       = %q{Ruby toolbox gem for Pioneer600.}
  spec.description   = %q{Swiss knife ruby tool for http://www.waveshare.com/wiki/Pioneer600.}
  spec.homepage      = "https://github.com/AskarZinurov/pioneer600."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'i2c'
  spec.add_runtime_dependency 'bcm2835'
  spec.add_runtime_dependency 'chunky_png'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
