# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multi-armed-bandit/version'

Gem::Specification.new do |gem|
  gem.name          = "multi-armed-bandit"
  gem.version       = MultiArmedBandit::VERSION
  gem.authors       = ["David Dai"]
  gem.email         = ["ddai@scribd.com"]
  gem.description   = %q{A Redis backed multi-armed bandit library.}
  gem.summary       = %q{A Redis backed multi-armed bandit library.}
  gem.homepage      = "https://github.com/newtonapple/multi-armed-bandit"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "redis", '~> 3.0.3'
end
