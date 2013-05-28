# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pretty_qr/version'

Gem::Specification.new do |spec|
  spec.name          = "pretty_qr"
  spec.version       = PrettyQr::VERSION
  spec.authors       = ["Benoit Marilleau"]
  spec.email         = ["benoit@marilleau.me"]
  spec.description   = %q{bla}
  spec.summary       = %q{blabla}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'rqrcode-rails3'
  spec.add_dependency 'mini_magick'
end
