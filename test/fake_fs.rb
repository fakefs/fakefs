$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs'
require 'test/unit'

class FakeFSTest < Test::Unit::TestCase
  def test_can_be_initialized_empty
    fs = FakeFS.new('.')
    assert_equal 0, fs.files.size
  end

  def test_can_be_initialized_with_an_existing_directory
    fs = FakeFS.new(File.expand_path(File.dirname(__FILE__)))
    assert_equal 1, fs.files.size
  end
end
