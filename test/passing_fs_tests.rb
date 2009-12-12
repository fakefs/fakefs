$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs_testhelper'
class AutoTests < Test::Unit::TestCase
  include FakeFsTestHelper

  def test_file_write
    compare_with_real do
      check_filesystem
      Dir.mkdir mp("somedir")
      Dir.mkdir mp("somedir/lol")
      file = File.open(mp("somedir/afile"), "w")
      file.write "hello world"
      file.close
      check_filesystem
    end
  end


  def test_file_read
    compare_with_real do
      Dir.mkdir mp("somedir")
      Dir.mkdir mp("somedir/lol")
      file = File.open(mp("somedir/afile"), "w")
      file.write "hello world"
      file.close
      check_value File.read mp("somedir/afile")
    end
  end

  def test_dir_search
    compare_with_real do
      Dir.mkdir mp("test")
      File.open(mp("comics.txt"), "w") { |f| f.write("test") }
      check_filesystem
      Dir.chdir base_path
      check_value Dir["*.txt"]
      check_value Dir["#{base_path}*.txt"]
    end
  end

  def test_fileutils_copy
    compare_with_real do
      File.open(mp("test.txt"), "w") { |f| f.write("hello") }
      Dir.mkdir "dir"
      check_value FileUtils.copy(mp('test.txt'), mp('dir/file.txt'))
      check_filesystem
    end
  end

end
      
      
