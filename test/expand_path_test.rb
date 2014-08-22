require "test_helper"

class ExpandPathTest < Test::Unit::TestCase
  def setup
    FakeFS.deactivate!
  end

  def teardown
    FakeFS.activate!
  end

  def test_expand_path_is_not_affected
    real_expand_path = File.expand_path('directory', '~/parent')
    FakeFS.activate!
    fake_expand_path = File.expand_path('directory', '~/parent')
    FakeFS.deactivate!

    assert_equal real_expand_path, fake_expand_path
  end
end
