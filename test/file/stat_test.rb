$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'fakefs/safe'
require 'test/unit'

class FileStatTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FileSystem.clear
  end

  def touch(*args)
    FileUtils.touch(*args)
  end

  def ln_s(*args)
    FileUtils.ln_s(*args)
  end

  def mkdir(*args)
    Dir.mkdir(*args)
  end

  def ln(*args)
    File.link(*args)
  end

  def test_file_stat_init_with_non_existant_file
    assert_raises(Errno::ENOENT) do
      File::Stat.new("/foo")
    end
  end

  def test_symlink_should_be_true_when_symlink
    touch("/foo")
    ln_s("/foo", "/bar")

    assert File::Stat.new("/bar").symlink?
  end

  def test_symlink_should_be_false_when_not_a_symlink
    FileUtils.touch("/foo")

    assert !File::Stat.new("/foo").symlink?
  end

  def test_should_return_false_for_directory_when_not_a_directory
    FileUtils.touch("/foo")

    assert !File::Stat.new("/foo").directory?
  end

  def test_should_return_true_for_directory_when_a_directory
    mkdir "/foo"

    assert File::Stat.new("/foo").directory?
  end

  def test_one_file_has_hard_link
    touch "testfile"
    assert_equal 1, File.stat("testfile").nlink
  end

  def test_two_hard_links_show_nlinks_as_two
    touch "testfile"
    ln    "testfile", "testfile.bak"

    assert_equal 2, File.stat("testfile").nlink
  end
end
