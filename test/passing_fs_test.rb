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


  def test_file_read_nested
    compare_with_real do
      Dir.mkdir mp("somedir")
      Dir.mkdir mp("somedir/lol")
      file = File.open(mp("somedir/afile"), "w")
      file.write "hello world"
      file.close
      check_value File.read mp("somedir/afile")
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

  def test_file_open
    compare_with_real do
      check_value File.open(mp("test.txt"), "w") { |f| f.write("hello") }
      check_filesystem
      Dir.mkdir mp("Home")

      file = File.open(mp("Home/comics.txt"), "a") do |f|                            
        f << "Cat and Girl: http://catandgirl.com/\n"                      
      end

      check_value file.inspect
      check_filesystem
    end
  end

  def test_file_read
    compare_with_real do
      input = <<EOF
comic_txt_text = <<COMIC_EOF
Achewood: http://achewood.com/
Dinosaur Comics: http://qwantz.com/
Perry Bible Fellowship: http://cheston.com/pbf/archive.html
Get Your War On: http://mnftiu.cc/
EOF
      File.open("comics.txt", "w") { |file| file << file.write(input) }

      check_filesystem
      check_value File.read("comics.txt")
    end
  end

  def test_file_foreach
    compare_with_real do
      input = <<EOF
line 1
line 2
line 3
line 4
EOF
      File.open("comics.txt", "w") { |file| file << file.write(input) }
      check_filesystem
      arr = []
      File.foreach("comics.txt") { |line| arr << line }
      check_value arr
    end
  end

      
      

end
      
      
