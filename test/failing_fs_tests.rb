$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs_testhelper'
class AutoTests < Test::Unit::TestCase
  include FakeFsTestHelper

  def test_symlink_creation
    compare_with_real do
      check_filesystem
      # Dir.mkdir(path + "somedir1" + rand().to_s)
      Dir.mkdir mp("somedir")
      Dir.mkdir mp("somedir/lol")
      File.symlink(mp("somedir"), mp("symlink"))
      check_filesystem
    end
  end


  def test_dir_entries
    compare_with_real do
      Dir.mkdir mp("somedir")
      Dir.mkdir mp("another")
      Dir.mkdir mp("third")
      check_filesystem
      check_value Dir.entries (mp ("."))
    end
  end
      


end

# $a = AutoTests.new
