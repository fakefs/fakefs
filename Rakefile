$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'test')

require 'bundler/setup'
require 'rake/testtask'
require File.expand_path(File.join(File.dirname(__FILE__), "lib", "fakefs", "version"))

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*test.rb']
  t.verbose = true
end

begin
  require 'rspec/core/rake_task'
  desc 'Run specs'
  RSpec::Core::RakeTask.new
rescue LoadError
  puts "Spec task can't be loaded. `gem install rspec`"
end

begin
  require 'rubocop/rake_task'
  desc 'Run RuboCop'
  RuboCop::RakeTask.new(:rubocop)
rescue LoadError
  puts "Rubocop task can't be loaded. `gem install rubocop`"
end

task default: [:test, :spec, :rubocop]

desc 'Push a new version to rubygems.org'
task :publish => [:test, :spec, :rubocop, :update_contributors, :tag, :release, :push]

desc 'Update contributors'
task :update_contributors do
  git_rank_contributors = "#{File.dirname(File.expand_path(__FILE__))}/etc/git-rank-contributors"

  sh "#{git_rank_contributors} > CONTRIBUTORS"
  if `git status | grep CONTRIBUTORS`.strip.length > 0
    sh "git add CONTRIBUTORS"
    sh "git commit -m 'Update contributors for release'"
  end
end

desc 'Release a new version'
task :release do
  sh "gem build fakefs.gemspec"
  sh "gem push fakefs-*.gem"
end

desc 'tag'
task :tag do
  version = FakeFS::Version::VERSION
  sh "git tag v#{version}"
  sh "git push --tags"
end

desc 'Run git push'
task :push do
  sh "git push origin master"
end
