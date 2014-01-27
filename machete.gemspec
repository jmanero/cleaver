# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'machete/version'

Gem::Specification.new do |spec|
  spec.name          = "machete"
  spec.version       = Machete::VERSION
  spec.authors       = ["John Manero"]
  spec.email         = ["jmanero@dyn.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "berkshelf", "= 2.0.12"
  spec.add_runtime_dependency "colorize"
  spec.add_runtime_dependency "growl"
  spec.add_runtime_dependency "ridley", "= 1.5.3"
  spec.add_runtime_dependency "thor", "= 0.18.1"
  spec.add_runtime_dependency "thor-scmversion", "= 1.4.0"
  spec.add_runtime_dependency "vagrant"

end
