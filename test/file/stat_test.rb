require_relative '../test_helper'

# File stat test class
class FileStatTest < Minitest::Test
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

  def test_file_stat_init_with_non_existent_file
    assert_raises(Errno::ENOENT) do
      File::Stat.new('/foo')
    end
  end

  def test_file_should_be_true_when_file
    touch('/foo')
    assert File::Stat.new('/foo').file?
  end

  def test_symlink_should_be_true_when_symlink
    touch('/foo')
    ln_s('/foo', '/bar')

    assert File::Stat.new('/bar').symlink?
    assert File::Stat.new('/bar').ftype == 'link'
  end

  def test_symlink_should_be_false_when_not_a_symlink
    FileUtils.touch('/foo')

    refute File::Stat.new('/foo').symlink?
    assert File::Stat.new('/foo').ftype == 'file'
  end

  def test_should_return_false_for_directory_when_not_a_directory
    FileUtils.touch('/foo')

    refute File::Stat.new('/foo').directory?
    assert File::Stat.new('/foo').ftype == 'file'
  end

  def test_should_return_true_for_directory_when_a_directory
    mkdir '/foo'

    assert File::Stat.new('/foo').directory?
    assert File::Stat.new('/foo').ftype == 'directory'
  end

  def test_writable_is_true
    touch('/foo')

    assert File::Stat.new('/foo').writable?
  end

  def test_readable_is_true
    touch('/foo')

    assert File::Stat.new('/foo').readable?
  end

  def test_one_file_has_hard_link
    touch 'testfile'
    assert_equal 1, File.stat('testfile').nlink
  end

  def test_two_hard_links_show_nlinks_as_two
    touch 'testfile'
    ln 'testfile', 'testfile.bak'

    assert_equal 2, File.stat('testfile').nlink
  end

  def test_file_size
    File.open('testfile', 'w') { |f| f << 'test' }
    assert_equal 4, File.stat('testfile').size
  end

  def test_file_zero?
    File.open('testfile', 'w') { |f| f << 'test' }
    refute File.stat('testfile').zero?, 'testfile has size 4, not zero'

    FileUtils.touch('testfile2')
    assert File.stat('testfile2').zero?, 'testfile2 has size 0, but stat lied'
  end

  def test_touch_modifies_mtime
    FileUtils.touch('/foo')
    mtime = File.mtime('/foo')

    FileUtils.touch('/foo')
    assert File.mtime('/foo') > mtime
  end

  def test_writing_to_file_modifies_mtime
    FileUtils.touch('/foo')
    mtime = File.mtime('/foo')

    File.open('/foo', 'w') { |f| f << 'test' }
    assert File.mtime('/foo') > mtime
  end

  def test_responds_to_world_writable
    FileUtils.touch('/foo')
    assert File::Stat.new('/foo').world_writable? == 0o777
  end

  def test_responds_to_sticky
    FileUtils.touch('/foo')
    refute File::Stat.new('/foo').sticky?
  end

  def test_responds_to_world_readable
    FileUtils.touch('/foo')
    assert File::Stat.new('/foo').world_readable? == 0o777, File::Stat.new('/foo').world_readable?.to_s
  end

  def test_can_open_tempfile
    FakeFS do
      require 'tempfile'
      FileUtils.mkdir_p('/tmp')
      ::Tempfile.open('test', '/tmp')
    end
  end

  def test_responds_to_realpath_only_on_1_9
    assert File.respond_to?(:realpath)
  end

  def test_responds_to_realdirpath_only_on_1_9_2_and_greater
    assert File.respond_to?(:realdirpath)
  end

  def test_file_path_exists
    assert File.respond_to?(:path)
  end

  def test_file_path_returns_correct_path
    assert File.path('/temp/test_file') == '/temp/test_file'
  end
end
