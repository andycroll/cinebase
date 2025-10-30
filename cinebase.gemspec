lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cinebase/version'

Gem::Specification.new do |spec|
  spec.name          = 'cinebase'
  spec.version       = Cinebase::VERSION
  spec.authors       = ['Andy Croll']
  spec.email         = ['andy@goodscary.com']

  spec.summary       = 'A base for cinema parsers to maintain a regular interface.'
  spec.description   = 'I maintain several gems for cinema times in the UK, this gem is the interface descriptor.'
  spec.homepage      = 'http://github.com/andycroll/cinebase'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'codeclimate-test-reporter'

  spec.add_runtime_dependency 'tzinfo'
  spec.add_runtime_dependency 'tzinfo-data'
end
