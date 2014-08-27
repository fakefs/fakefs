# -*- coding: utf-8 -*-
require "test_helper"

class DirTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  # Directory tests
  def test_new_directory
    FileUtils.mkdir_p(sample_nested_dir)

    assert_nothing_raised do
      Dir.new(sample_nested_dir)
    end
  end

  def test_new_directory_does_not_work_if_dir_path_cannot_be_found
    assert_raises(Errno::ENOENT) do
      Dir.new('/this/path/should/not/be/here')
    end
  end

  def test_directory_close
    FileUtils.mkdir_p(sample_nested_dir)
    dir = Dir.new(sample_nested_dir)
    assert dir.close.nil?

    assert_raises(IOError) do
      dir.each { |dir| dir }
    end
  end

  def test_directory_path
    FileUtils.mkdir_p(sample_nested_dir)
    good_path = sample_nested_dir
    assert_equal good_path, Dir.new(sample_nested_dir).path
  end

  def test_directory_class_delete_does_not_work_if_dir_path_cannot_be_found
    assert_raises(Errno::ENOENT) do
      Dir.delete('/this/path/should/not/be/here')
    end
  end

  def test_directory_class_delete
    FileUtils.mkdir_p(sample_nested_dir)
    Dir.delete(sample_nested_dir)
    assert_equal false, File.exists?(sample_nested_dir)
  end

  # =================== BEGIN BLOCK ======================
  def files
    default_files + sample_filenames
  end

  def sample_nested_dir
    '/this/path/should/be/here'
  end

  def test_directory_each
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    yielded = []
    dir.each { |file| yielded << file }

    assert_equal yielded.size, files.size
    files.each { |t| assert yielded.include?(t) }
  end

  def test_directory_pos
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    assert_equal dir.pos, 0
    dir.read
    assert_equal dir.pos, 1
    dir.read
    assert_equal dir.pos, 2
    dir.read
    assert_equal dir.pos, 3
    dir.read
    assert_equal dir.pos, 4
    dir.read
    assert_equal dir.pos, 5
  end

  def test_directory_pos_assign
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    assert_equal dir.pos, 0
    dir.pos = 2
    assert_equal dir.pos, 2
  end

  def test_directory_read
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    assert_equal dir.pos, 0
    d = dir.read
    assert_equal dir.pos, 1
    assert_equal d, '.'

    d = dir.read
    assert_equal dir.pos, 2
    assert_equal d, '..'
  end

  def test_directory_read_past_length
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_not_nil d
    d = dir.read
    assert_nil d
  end

  def test_directory_rewind
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    d = dir.read
    d = dir.read
    assert_equal dir.pos, 2
    dir.rewind
    assert_equal dir.pos, 0
  end

  def test_directory_seek
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.new(sample_nested_dir)

    d = dir.seek 1
    assert_equal d, '..'
    assert_equal dir.pos, 1
  end

  def test_directory_class_delete_does_not_act_on_non_empty_directory
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    assert_raises(Errno::ENOTEMPTY) do
      Dir.delete(sample_nested_dir)
    end
  end

  def test_directory_entries
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    yielded = Dir.entries(sample_nested_dir)
    assert_equal yielded.size, files.size
    files.each { |t| assert yielded.include?(t) }
  end

  def test_directory_entries_works_with_trailing_slash
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    yielded = Dir.entries('/this/path/should/be/here/')
    assert_equal yielded.size, files.size
    files.each { |t| assert yielded.include?(t) }
  end

  def test_directory_foreach_relative_paths
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    yielded = []
    Dir.chdir '/this/path/should/be' do
      Dir.foreach('here') { |file| yielded << file }
    end

    assert_equal yielded.size, files.size, 'wrong number of files yielded'
    files.each { |t| assert yielded.include?(t), "#{t} was not included in #{yielded.inspect}" }
  end

  def test_directory_foreach
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files sample_filenames, :dir => sample_nested_dir

    yielded = []
    Dir.foreach(sample_nested_dir) { |file| yielded << file }

    assert_equal yielded.size, files.size
    sample_filenames.each { |f| assert yielded.include?(f) }
  end

  def test_directory_open
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    dir = Dir.open(sample_nested_dir)
    assert_equal dir.path, sample_nested_dir
  end

  def test_directory_open_block
    FileUtils.mkdir_p(sample_nested_dir)
    touch_files files, :dir => sample_nested_dir

    yielded = []
    Dir.open(sample_nested_dir) { |file| yielded << file }

    assert_equal yielded.size, files.size
    files.each { |t| assert yielded.include?(t) }
  end

  def sample_filenames
    %w{file_1 file_2 file_3 file_4 file_5}
  end

  def default_files
    ['.', '..']
  end
  # ============================ END BLOCK ========================

  def test_directory_entries_does_not_work_if_dir_path_cannot_be_found
    assert_raises(Errno::ENOENT) do
      Dir.delete('/this/path/should/not/be/here')
    end
  end

  def test_directory_mkdir
    Dir.mkdir('/path')
    assert File.exists?('/path')
  end

  def test_directory_mkdir_nested
    Dir.mkdir("/tmp")
    Dir.mkdir("/tmp/stream20120103-11847-xc8pb.lock")
    assert File.exists?("/tmp/stream20120103-11847-xc8pb.lock")
  end

  def test_can_create_subdirectories_with_dir_mkdir
    Dir.mkdir 'foo'
    Dir.mkdir 'foo/bar'
    assert Dir.exists?('foo/bar')
  end

  def test_can_create_absolute_subdirectories_with_dir_mkdir
    Dir.mkdir '/foo'
    Dir.mkdir '/foo/bar'
    assert Dir.exists?('/foo/bar')
  end

  def test_can_create_directories_starting_with_dot
    Dir.mkdir './path'
    assert File.exists? './path'
  end

  def test_directory_mkdir_relative
    FileUtils.mkdir_p('/new/root')
    FileSystem.chdir('/new/root')
    Dir.mkdir('path')
    assert File.exists?('/new/root/path')
  end

  def test_directory_mkdir_not_recursive
    assert_raises(Errno::ENOENT) do
      Dir.mkdir('/path/does/not/exist')
    end
  end

  def test_mkdir_raises_error_if_already_created
    Dir.mkdir "foo"

    assert_raises(Errno::EEXIST) do
      Dir.mkdir "foo"
    end
  end

  def test_directory_exists
    assert_equal Dir.exists?(sample_nested_dir), false
    assert_equal Dir.exist?(sample_nested_dir), false
    FileUtils.mkdir_p(sample_nested_dir)
    assert_equal Dir.exists?(sample_nested_dir), true
    assert_equal Dir.exist?(sample_nested_dir), true
  end

  def test_tmpdir
    assert_equal Dir.tmpdir, "/tmp"
  end

  def test_chdir_shouldnt_lose_state_because_of_errors
    FileUtils.mkdir_p '/path'

    Dir.chdir '/path' do
      File.open('foo', 'w') { |f| f.write 'foo'}
      File.open('foobar', 'w') { |f| f.write 'foo'}
    end

    begin
      Dir.chdir('/path') do
        raise Exception
      end
    rescue Exception # hardcore
    end

    Dir.chdir('/path') do
      begin
        Dir.chdir('nope'){ }
      rescue Errno::ENOENT
      end

      assert_equal ['/', '/path'], FileSystem.dir_levels
    end

    assert_equal(['/path/foo', '/path/foobar'], Dir.glob('/path/*').sort)
  end
end
