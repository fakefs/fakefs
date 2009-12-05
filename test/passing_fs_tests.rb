$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs_testhelper'
class AutoTests < Test::Unit::TestCase
  include FakeFsTestHelper

  def test_file_write
    compare_with_real do |path|
      check_filesystem
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "somedir/lol")
      file = File.open("#{path}somedir/afile", "w")
      file.write "hello world"
      file.close
      check_filesystem
    end
  end


  def test_file_read
    compare_with_real do |path|
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "somedir/lol")
      file = File.open("#{path}somedir/afile", "w")
      file.write "hello world"
      file.close
      check_value File.read("#{path}somedir/afile")
    end
  end
end
      
      
