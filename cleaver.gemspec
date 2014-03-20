# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "cleaver"
  spec.version       = IO.read(File.expand_path('../VERSION', __FILE__)) rescue "0.0.1"
  spec.authors       = ["John Manero"]
  spec.email         = ["jmanero@dyn.com"]
  spec.description   = %q{Manage the lifecycle of a deployment with Chef}
  spec.summary       = %q{Manage the lifecycle of a deployment with Chef}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "geminabox", "~> 0.12.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop", "= 0.18.1"
  spec.add_development_dependency "thor-scmversion"


  spec.add_runtime_dependency "berkshelf", "= 2.0.12"
  spec.add_runtime_dependency "colorize"
  spec.add_runtime_dependency "growl"
  spec.add_runtime_dependency "ridley", "= 1.5.3"
  spec.add_runtime_dependency "thor", "= 0.18.1"
  spec.add_runtime_dependency "thor-scmversion", "= 1.4.0"
end
