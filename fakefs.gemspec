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

  spec.required_ruby_version = '>= 2.7.0'
  spec.add_development_dependency 'bump', '~> 0.5.3'
  spec.add_development_dependency 'maxitest', '~> 3.6'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '>= 10.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rubocop', '~> 0.82.0'

  # It is good practice to have all deps listed, they will appear in the Gemfile.lock and allow reproducible builds
  # For an unknown reason the github CI does not like when "pathname" is added
  spec.add_runtime_dependency 'english'
  spec.add_runtime_dependency 'fileutils'
  spec.add_runtime_dependency 'find'
  spec.add_runtime_dependency 'irb'
  spec.add_runtime_dependency 'stringio'
end
