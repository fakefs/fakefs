$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs/safe'
require 'test/unit'

begin
  require 'redgreen'
rescue LoadError
end

def act_on_real_fs
  raise ArgumentError unless block_given?
  FakeFS.deactivate!
  yield
  FakeFS.activate!
end
