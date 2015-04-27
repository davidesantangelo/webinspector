# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require File.expand_path('../lib/web_inspector/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "webinspector"
  spec.version       = WebInspector::VERSION
  spec.authors       = ["Davide Santangelo"]
  spec.email         = ["davide.santangelo@gmail.com"]

  spec.summary       = %q{Ruby gem to inspect completely a web page.}
  spec.description   = %q{Ruby gem to inspect completely a web page. It scrapes a given URL, and returns you its meta, links, images and more.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "typhoeus"

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_dependency "faraday"
  spec.add_dependency "json"
  spec.add_dependency "addressable"
  spec.add_dependency "nokogiri"
  spec.add_dependency "open_uri_redirections"
  spec.add_dependency "openurl"
end
