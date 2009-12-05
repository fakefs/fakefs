$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs_testhelper'
class AutoTests < Test::Unit::TestCase
  include FakeFsTestHelper

  def test_symlink_creation
    compare_with_real do |path|
      check_filesystem
      # Dir.mkdir(path + "somedir1" + rand().to_s)
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "somedir/lol")
      File.symlink(path + "somedir", path + "symlink")
      check_filesystem
    end
  end


  def test_dir_entries
    compare_with_real do |path|
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "another")
      Dir.mkdir(path + "third")
      check_filesystem
      check_value Dir.entries path
    end
  end
      


end

# $a = AutoTests.new
