require "test_helper"

class ExpandPathTest < Test::Unit::TestCase
  def setup
    FakeFS.deactivate!
  end

  def teardown
    FakeFS.activate!
  end

  def test_expand_path_is_not_affected_1
    assert_expand_path_behavior_is_unchanged('directory', '/parent')
  end

  def test_expand_path_is_not_affected_2
    assert_expand_path_behavior_is_unchanged('directory', '~/parent')
  end

  def test_expand_path_is_affected_1
    assert_expand_path_behavior_is_changed('directory', 'parent')
  end

  def test_expand_path_is_affected_2
    assert_expand_path_behavior_is_changed('directory')
  end

  private
  def assert_expand_path_behavior_is_unchanged *args
    real_expand_path = File.expand_path(*args)
    FakeFS.activate!
    fake_expand_path = File.expand_path(*args)
    FakeFS.deactivate!

    assert_equal real_expand_path, fake_expand_path
  end

  def assert_expand_path_behavior_is_changed *args
    real_expand_path = File.expand_path(*args)
    FakeFS.activate!
    fake_expand_path = File.expand_path(*args)
    FakeFS.deactivate!

    refute_equal real_expand_path, fake_expand_path
  end
end
