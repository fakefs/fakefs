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

  spec.required_ruby_version = '>= 2.3.0'
  spec.add_development_dependency 'bump', '~> 0.5.3'
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'minitest-rg', '~> 5.1'
  spec.add_development_dependency 'rake', '>= 10.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rubocop', '~> 0.58.1'
end
