require 'fakefs/base'

def FakeFS
  return ::FakeFS unless block_given?
  ::FakeFS.activate!
  yield
  ::FakeFS.deactivate!
end
