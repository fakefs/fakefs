# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'bump/tasks'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*test.rb']
  t.verbose = true
  t.warning = true
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = '--warnings'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: [:test, :spec, :rubocop]

desc 'Update contributors'
task :update_contributors do
  git_rank_contributors = File.expand_path('etc/git-rank-contributors', __dir__)
  Bundler.with_unbundled_env do
    sh "ruby #{git_rank_contributors} > CONTRIBUTORS && git add CONTRIBUTORS"
  end
end

namespace :bump do
  Bump::Bump::BUMPS.each do |step|
    task step => :update_contributors
  end
end
