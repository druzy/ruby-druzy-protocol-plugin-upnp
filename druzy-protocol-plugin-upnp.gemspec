# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'druzy/protocol/plugin/upnp/version'

Gem::Specification.new do |spec|
  spec.name          = "druzy-protocol-plugin-upnp"
  spec.version       = Druzy::Protocol::Plugin::Upnp::VERSION
  spec.authors       = ["Jonathan Le Greneur"]
  spec.email         = ["jonathan.legreneur@free.fr"]

  spec.summary       = %q{Plugin to discover a upnp media renderer}
  spec.description   = %q{Plugin to discover a upnp media renderer, just install it}
  spec.homepage      = "https://github.com/druzy/ruby-druzy-protocol-plugin-upnp"
  spec.license       = "MIT"

  spec.files         = `find lib -type f`.split("\n")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'druzy-protocol', '>= 1.0.2'
  spec.add_runtime_dependency 'druzy-server', '>= 1.0.0'
  spec.add_runtime_dependency 'druzy-upnp', '>= 2.0.1'
  spec.add_runtime_dependency 'ruby-filemagic', '>= 0.7.1'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
