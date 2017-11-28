# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shoryuken/batch/version'

Gem::Specification.new do |spec|
  spec.name          = 'shoryuken-batch'
  spec.version       = Shoryuken::Batch::VERSION
  spec.authors       = ['Bin Huang']
  spec.email         = ['huangbin88@foxmail.com']

  spec.summary       = 'Shoryuken Batch Jobs'
  spec.description   = 'Shoryuken Batch Jobs Implementation'
  spec.homepage      = 'https://github.com/hbin/shoryuken-batch'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'shoryuken'

  spec.add_development_dependency 'bundler', "~> 1.12"
  spec.add_development_dependency 'rake', "~> 10.0"
  spec.add_development_dependency 'rspec', "~> 3.0"
  spec.add_development_dependency 'fakeredis', "~> 0.5.0"
end
