require 'bundler/setup'
require 'fakefs/safe'
require 'minitest/autorun'
require 'minitest/rg'

def act_on_real_fs(&block)
  FakeFS.without(&block)
end

module Minitest
  class Test
    # Minitest::Test#diff needs to write to the filesystem in order to produce
    # the nice diffs we see when a test fails. For this to work it needs to
    # access the real filesystem.
    def diff(expected, actual)
      act_on_real_fs { super(expected, actual) }
    end
  end
end

def capture_stderr
  real_stderr, $stderr = $stderr, StringIO.new

  # force FileUtils to use our stderr
  RealFileUtils.instance_variable_set('@fileutils_output', $stderr)

  yield

  $stderr.string
ensure
  $stderr = real_stderr

  # restore FileUtils stderr
  RealFileUtils.instance_variable_set('@fileutils_output', $stderr)
end

def real_file_sandbox(path = nil)
  base_path = real_file_sandbox_path
  path ? File.join(base_path, path) : base_path
end

def real_file_sandbox_path
  File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_sandbox'))
end
