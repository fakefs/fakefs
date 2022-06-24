require_relative 'test_helper'

# Trivial IO test class
# Behavior is not really tested, as call is forwarded to File class
class IOTest < Minitest::Test
  def test_method_IO_read_works
    ::FakeFS.activate!(io_mocks: true)
    ::File.write('foo', 'bar')

    assert_equal 'bar', ::IO.read('foo')

    ::FakeFS.deactivate!
    refute ::File.exist?('foo')
  end

  def test_method_IO_write_works
    ::FakeFS.activate!(io_mocks: true)
    ::IO.write('foo', 'bar')

    assert_equal 'bar', ::File.read('foo')

    ::FakeFS.deactivate!
    refute ::File.exist?('foo')
  end

  def test_method_IO_binread_works
    ::FakeFS.activate!(io_mocks: true)
    ::File.write('foo', 'bar')

    assert_equal 'bar', ::IO.binread('foo')

    ::FakeFS.deactivate!
    refute ::File.exist?('foo')
  end
end
