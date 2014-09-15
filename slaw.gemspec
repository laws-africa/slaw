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
  spec.description   = %q{Slaw is a lightweight library for manipulating Akoma Ntoso acts in Ruby.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
