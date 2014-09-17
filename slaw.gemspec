# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slaw/version'

Gem::Specification.new do |spec|
  spec.name          = "slaw"
  spec.version       = Slaw::VERSION
  spec.authors       = ["Greg Kempe"]
  spec.email         = ["greg@kempe.net"]
  spec.summary       = %q{A lightweight library for using Akoma Ntoso acts in Ruby.}
  spec.description   = %q{Slaw is a lightweight library for rendering and generating Akoma Ntoso acts from plain text and PDF documents.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14.1"

  spec.add_runtime_dependency "nokogiri", "~> 1.6.0"
  spec.add_runtime_dependency "treetop", "~> 1.5"
  spec.add_runtime_dependency "builder", "~> 3.2.2"
  spec.add_runtime_dependency "log4r", "~> 1.1.10"
end
