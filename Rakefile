require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'bump/tasks'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*test.rb']
  t.verbose = true
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: [:test, :spec, :rubocop]

desc 'Push a new version to rubygems.org'
task publish: [:rubocop, :test, :spec, :rubocop, :update_contributors, :release]

desc 'Update contributors'
task :update_contributors do
  git_rank_contributors = "#{File.dirname(File.expand_path(__FILE__))}/etc/git-rank-contributors"

  sh "#{git_rank_contributors} > CONTRIBUTORS"
  if `git status | grep CONTRIBUTORS`.strip.length > 0
    sh 'git add CONTRIBUTORS'
    sh "git commit -m 'Update contributors for release'"
  end
end
