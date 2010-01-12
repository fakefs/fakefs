$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'test')

desc "Run tests"
task :test do
  Dir['test/**/*_test.rb'].each { |file| require file }
end

task :default => [:test, :spec]

begin
  require 'spec/rake/spectask'

  desc "Run specs"
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_files = FileList["spec/**/*.rb"]
  end
rescue LoadError
  puts "Spec task can't be loaded. `gem install rspec`"
end

begin
  require 'jeweler'

  $LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
  require 'fakefs/version'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = "fakefs"
    gemspec.summary     = "A fake filesystem. Use it in your tests."
    gemspec.email       = "chris@ozmm.org"
    gemspec.homepage    = "http://github.com/defunkt/fakefs"
    gemspec.description = "A fake filesystem. Use it in your tests."
    gemspec.authors     = ["Chris Wanstrath"]
    gemspec.has_rdoc    = false
    gemspec.version     = FakeFS::Version.to_s
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

desc "Build a gem"
task :gem => [ :gemspec, :build ]

desc "Push a new version to Gemcutter"
task :publish => [ :gemspec, :build ] do
  abort("Tests failed!") unless system("rake test")
  system "git tag v#{FakeFS::Version}"
  system "git push origin v#{FakeFS::Version}"
  system "git push origin master"
  system "gem push pkg/fakefs-#{FakeFS::Version}.gem"
  system "git clean -fd"
  exec "rake pages"
end
