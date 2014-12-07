$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'test')

require 'bundler/setup'
require 'rake/testtask'

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
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = false
  end
rescue LoadError
  puts "Rubocop task can't be loaded. `gem install rubocop`"
end

task default: [:spec, :test, :rubocop]

desc 'Push a new version to rubygems.org'
task :publish do
  abort('Tests failed!') unless system('rake test')
  Rake::Task[:release].invoke
end

desc 'Update contributors'
task :update_contributors do
  sh 'git-rank-contributors > CONTRIBUTORS'
end
