desc "Run tests"
task :test do
  Dir['test/**/*_test.rb'].each { |file| require file }
end

task :default => :test

begin
  require 'jeweler'

  $LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
  require 'fakefs/version'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "fakefs"
    gemspec.summary = "A fake filesystem. Use it in your tests."
    gemspec.email = "chris@ozmm.org"
    gemspec.homepage = "http://github.com/defunkt/fakefs"
    gemspec.description = "A fake filesystem. Use it in your tests."
    gemspec.authors = ["Chris Wanstrath"]
    gemspec.has_rdoc = false
    gemspec.version = FakeFS::Version.to_s
  end
rescue LoadError
  puts "Jeweler not available."
  puts "Install it with: gem install jeweler"
end

begin
  require 'sdoc_helpers'
rescue LoadError
  puts "sdoc support not enabled. Please gem install sdoc-helpers."
end
