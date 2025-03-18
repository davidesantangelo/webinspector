# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require File.expand_path('lib/web_inspector/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'webinspector'
  spec.version       = WebInspector::VERSION
  spec.authors       = ['Davide Santangelo']
  spec.email         = ['davide.santangelo@gmail.com']

  spec.summary       = 'Ruby gem to inspect completely a web page.'
  spec.description   = 'Ruby gem to inspect completely a web page. It scrapes a given URL, and returns you its meta, links, images and more.'
  spec.homepage      = 'https://github.com/davidesantangelo/webinspector'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.metadata      = {
    'source_code_uri' => 'https://github.com/davidesantangelo/webinspector',
    'bug_tracker_uri' => 'https://github.com/davidesantangelo/webinspector/issues'
  }

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'

  spec.add_dependency 'addressable', '~> 2.8'
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'faraday-cookie_jar', '~> 0.0.7'
  spec.add_dependency 'faraday-follow_redirects', '~> 0.3'
  spec.add_dependency 'faraday-retry', '~> 2.1'
  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'nokogiri', '~> 1.14'
  spec.add_dependency 'open_uri_redirections', '~> 0.2'
  spec.add_dependency 'openurl', '~> 1.0'
  spec.add_dependency 'public_suffix', '~> 5.0'
end
