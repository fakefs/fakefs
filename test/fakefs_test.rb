$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs'
require 'test/unit'

class FakeFSTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FileSystem.clear
  end

  def test_can_be_initialized_empty
    fs = FileSystem
    assert_equal 0, fs.files.size
  end

  def xtest_can_be_initialized_with_an_existing_directory
    fs = FileSystem
    fs.clone(File.expand_path(File.dirname(__FILE__))).inspect
    puts fs.files.inspect
    assert_equal 1, fs.files.size
  end

  def test_can_create_directories
    FileUtils.mkdir_p("/path/to/dir")
    assert_kind_of MockDir, FileSystem.fs['path']['to']['dir']
  end

  def test_knows_directories_exist
    FileUtils.mkdir_p(path = "/path/to/dir")
    assert File.exists?(path)
  end

  def test_knows_directories_are_directories
    FileUtils.mkdir_p(path = "/path/to/dir")
    assert File.directory?(path)
  end

  def test_can_create_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, "/path/to/link")
    assert_kind_of MockSymlink, FileSystem.fs['path']['to']['link']
  end

  def test_can_follow_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, link = "/path/to/symlink")
    assert_equal target, File.readlink(link)
  end

  def test_knows_symlinks_are_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, link = "/path/to/symlink")
    assert File.symlink?(link)
  end

  def test_can_create_files
    path = '/path/to/file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert File.exists?(path)
  end

  def test_can_read_files_once_written
    path = '/path/to/file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert_equal "Yatta!", File.read(path)
  end

  def test_knows_files_are_files
    path = '/path/to/file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert File.file?(path)
  end
end
