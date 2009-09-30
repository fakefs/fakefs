task :default do
  Dir['test/**/*_test.rb'].each { |file| require file }
end

begin
  require 'jeweler'

  # We're not putting VERSION or VERSION.yml in the root,
  # so we have to help Jeweler find our version.
  $LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
  require 'fakefs/version'

  FakeFS::Version.instance_eval do
    def refresh
    end
  end

  class Jeweler
    def version_helper
      FakeFS::Version
    end

    def version_exists?
      true
    end
  end

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "fakefs"
    gemspec.summary = "A fake filesystem. Use it in your tests."
    gemspec.email = "chris@ozmm.org"
    gemspec.homepage = "http://github.com/defunkt/fakefs"
    gemspec.description = "A fake filesystem. Use it in your tests."
    gemspec.authors = ["Chris Wanstrath"]
    gemspec.has_rdoc = false
  end
rescue LoadError
  puts "Jeweler not available."
  puts "Install it with: gem install technicalpickles-jeweler"
end
