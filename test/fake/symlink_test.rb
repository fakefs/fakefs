require_relative '../test_helper'

# Fake symlink test class
class FakeSymlinkTest < Minitest::Test
  include FakeFS

  def test_symlink_has_method_missing_as_private
    methods = FakeSymlink.private_instance_methods.map(&:to_s)
    assert methods.include?('method_missing')
  end

  def test_symlink_respond_to_accepts_multiple_params
    fake_symlink = FakeSymlink.new('foo')
    assert fake_symlink.respond_to?(:to_s, false),
           'has public method \#to_s'
    assert fake_symlink.respond_to?(:to_s, true),
           'has public or private method \#to_s'
    refute fake_symlink.respond_to?(:initialize, false),
           'has private method \#initialize'
    assert fake_symlink.respond_to?(:initialize, true),
           'has private method \#initialize'
  end

  def test_symlink_respond_to_uses_same_param_defaults
    fake_symlink = FakeSymlink.new('foo')
    assert_equal fake_symlink.respond_to?(:to_s),
                 fake_symlink.entry.respond_to?(:to_s)
    refute_equal fake_symlink.respond_to?(:to_s),
                 fake_symlink.entry.respond_to?(:initialize)
    assert_equal fake_symlink.respond_to?(:initialize),
                 fake_symlink.entry.respond_to?(:initialize)
  end
end
