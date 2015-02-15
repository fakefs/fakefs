$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs/safe'
require 'minitest/autorun'
require 'minitest/rg'

def act_on_real_fs(&block)
  FakeFS.without(&block)
end

def capture_stderr
  real_stderr, $stderr = $stderr, StringIO.new

  # force FileUtils to use our stderr
  RealFileUtils.instance_variable_set('@fileutils_output', $stderr)

  yield

  return $stderr.string
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
