# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/throttler/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-throttler'
  spec.version       = Rack::Throttler::VERSION
  spec.authors       = ['Leslie Fung']
  spec.email         = ['leslie.fung.lf@gmail.com']

  spec.summary       = 'Middleware to throttle (rate limit) requests in Rack apps'
  spec.description   = 'Middleware that can let Rack apps throttle (rate limit) requests'
  spec.homepage      = 'https://github.com/lfportal/rack-throttler'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'redis', '~> 3.3'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rack-test', '~> 0.6'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.48.1'
  spec.add_development_dependency 'timecop', '~> 0.8'
end
