# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fakefs/require/version"

Gem::Specification.new do |s|
  s.name        = "fakefs-require"
  s.version     = FakeFS::Require::VERSION
  s.date        = Date.today.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Lars Gierth"]
  s.email       = ["lars.gierth@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/fakefs-require"
  s.summary     = %q{Faked #require, #load and #autoload for defunkt's FakeFS}
  
  s.add_dependency "fakefs"

  s.add_development_dependency "test-unit"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rack"

  s.files         = `git ls-files`.split("\n") - [".gitignore", ".rvmrc"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
