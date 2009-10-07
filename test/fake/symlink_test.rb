$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'fakefs/safe'
require 'test/unit'

class FakeSymlinkTest < Test::Unit::TestCase
  include FakeFS

  def test_symlink_has_method_missing_as_private
    methods = FakeSymlink.private_instance_methods.map { |m| m.to_s }
    assert methods.include?("method_missing")
  end
end
