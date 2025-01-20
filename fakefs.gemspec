require './lib/fakefs/version'

Gem::Specification.new do |spec|
  spec.name          = 'fakefs'
  spec.version       = FakeFS::Version.to_s
  spec.authors       = ['Chris Wanstrath', 'Scott Taylor', 'Jeff Hodges', 'Pat Nakajima', 'Brian Donovan']
  spec.email         = ['chris@ozmm.org']
  spec.description   = 'A fake filesystem. Use it in your tests.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/fakefs/fakefs'
  spec.license       = 'MIT'

  spec.files         = `git ls-files lib README.md LICENSE`.split($/)

  spec.required_ruby_version = '>= 3.0.0'
  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'maxitest'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 1.70.0' # locked down to prevent random new validations
end
