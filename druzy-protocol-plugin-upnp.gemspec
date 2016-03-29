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

  spec.files         = Dir['lib/druzy/protocol/plugin/*.rb']+Dir['lib/druzy/protocol/plugin/upnp/*.rb']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'druzy-protocol', '~> 0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
