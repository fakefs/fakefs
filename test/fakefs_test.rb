# -*- coding: utf-8 -*-
require "test_helper"

class FakeFSTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_symlink_with_missing_refferent_does_not_exist
    File.symlink('/foo', '/bar')
    assert !File.exists?('/bar')
  end

  def test_can_create_files_in_current_dir
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert File.exists?(path)
    assert File.readable?(path)
    assert File.writable?(path)
  end

  def test_can_create_files_in_existing_dir
    FileUtils.mkdir_p "/path/to"
    path = "/path/to/file.txt"

    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert File.exists?(path)
    assert File.readable?(path)
    assert File.writable?(path)
  end

  def test_raises_ENOENT_trying_to_create_files_in_nonexistent_dir
    path = "/path/to/file.txt"

    assert_raises(Errno::ENOENT) {
      File.open(path, 'w') do |f|
        f.write "Yatta!"
      end
    }
  end

  def test_raises_ENOENT_trying_to_create_files_in_relative_nonexistent_dir
    FileUtils.mkdir_p "/some/path"

    Dir.chdir("/some/path") {
      assert_raises(Errno::ENOENT) {
        File.open("../foo") {|f| f.write "moo" }
      }
    }
  end

  def test_raises_ENOENT_trying_to_create_files_in_obscured_nonexistent_dir
    FileUtils.mkdir_p "/some/path"

    assert_raises(Errno::ENOENT) {
      File.open("/some/path/../foo") {|f| f.write "moo" }
    }
  end

  def test_raises_ENOENT_trying_to_create_tilde_referenced_nonexistent_dir
    path = "~/fakefs_test_#{$$}_0000"

    while File.exist? path
      path = path.succ
    end

    assert_raises(Errno::ENOENT) {
      File.open("#{path}/foo") {|f| f.write "moo" }
    }
  end

  def test_raises_EISDIR_if_trying_to_open_existing_directory_name
    path = "/path/to"

    FileUtils.mkdir_p path

    assert_raises(Errno::EISDIR) {
      File.open(path, 'w') do |f|
        f.write "Yatta!"
      end
    }
  end

  def test_can_create_files_with_bitmasks
    FileUtils.mkdir_p("/path/to")

    path = '/path/to/file.txt'
    File.open(path, File::RDWR | File::CREAT) do |f|
      f.write "Yatta!"
    end

    assert File.exists?(path)
    assert File.readable?(path)
    assert File.writable?(path)
  end

  def test_file_opens_in_read_only_mode
    File.open("foo", "w") { |f| f << "foo" }

    f = File.open("foo")

    assert_raises(IOError) do
      f << "bar"
    end
  end

  def test_file_opens_in_read_only_mode_with_bitmasks
    File.open("foo", "w") { |f| f << "foo" }

    f = File.open("foo", File::RDONLY)

    assert_raises(IOError) do
      f << "bar"
    end
  end

  def test_file_opens_in_invalid_mode
    FileUtils.touch("foo")

    assert_raises(ArgumentError) do
      File.open("foo", "an_illegal_mode")
    end
  end

  def test_raises_error_when_cannot_find_file_in_read_mode
    assert_raises(Errno::ENOENT) do
      File.open("does_not_exist", "r")
    end
  end

  def test_raises_error_when_cannot_find_file_in_read_write_mode
    assert_raises(Errno::ENOENT) do
      File.open("does_not_exist", "r+")
    end
  end

  def test_creates_files_in_write_only_mode
    File.open("foo", "w")
    assert File.exists?("foo")
  end

  def test_creates_files_in_write_only_mode_with_bitmasks
    File.open("foo", File::WRONLY | File::CREAT)
    assert File.exists?("foo")
  end

  def test_raises_in_write_only_mode_without_create_bitmask
    assert_raises(Errno::ENOENT) do
      File.open("foo", File::WRONLY)
    end
  end

  def test_creates_files_in_read_write_truncate_mode
    File.open("foo", "w+")
    assert File.exists?("foo")
  end

  def test_creates_files_in_append_write_only
    File.open("foo", "a")
    assert File.exists?("foo")
  end

  def test_creates_files_in_append_read_write
    File.open("foo", "a+")
    assert File.exists?("foo")
  end

  def test_file_in_write_only_raises_error_when_reading
    FileUtils.touch("foo")

    f = File.open("foo", "w")

    assert_raises(IOError) do
      f.read
    end
  end

  def test_file_in_write_mode_truncates_existing_file
    File.open("foo", "w") { |f| f << "contents" }

    f = File.open("foo", "w")

    assert_equal "", File.read("foo")
  end

  def test_file_in_read_write_truncation_mode_truncates_file
    File.open("foo", "w") { |f| f << "foo" }

    f = File.open("foo", "w+")

    assert_equal "", File.read("foo")
  end

  def test_file_in_append_write_only_raises_error_when_reading
    FileUtils.touch("foo")

    f = File.open("foo", "a")

    assert_raises(IOError) do
      f.read
    end
  end

  def test_can_read_files_once_written
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert_equal "Yatta!", File.read(path)
  end

  def test_file_read_accepts_hashes
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write 'Yatta!'
    end

    assert_nothing_raised { File.read(path, :mode => 'r:UTF-8:-') }
  end

  def test_file_read_respects_args
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write 'Yatta!'
    end

    assert_equal 'Ya', File.read(path, 2)
    assert_equal 'at', File.read(path, 2, 1)
    assert_equal 'atta!', File.read(path, nil, 1)
  end

  def test_can_write_to_files
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << 'Yada Yada'
    end
    assert_equal 'Yada Yada', File.read(path)
  end

  def test_raises_error_when_opening_with_binary_mode_only
    assert_raise ArgumentError do
      File.open("/foo", "b")
    end
  end

  def test_can_open_file_in_binary_mode
    File.open("foo", "wb") { |x| x << "a" }
    assert_equal "a", File.read("foo")
  end

  def test_can_chunk_io_when_reading
    FileUtils.mkdir_p "/path/to"
    path = '/path/to/file.txt'
    File.open(path, 'w') do |f|
      f << 'Yada Yada'
    end
    file = File.new(path, 'r')
    assert_equal 'Yada', file.read(4)
    assert_equal ' Yada', file.read(5)
    assert_equal '', file.read
    file.rewind
    assert_equal 'Yada Yada', file.read
  end

  def test_can_get_size_of_files
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << 'Yada Yada'
    end
    assert_equal 9, File.size(path)
  end

  def test_can_get_correct_size_for_files_with_multibyte_characters
    path = 'file.txt'
    File.open(path, 'wb') do |f|
      f << "Y\xC3\xA1da" # Yáda
    end
    assert_equal 5, File.size(path)
  end

  def test_can_check_if_file_has_size?
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << 'Yada Yada'
    end
    assert_equal 9, File.size?(path)
    assert_nil File.size?("other.txt")
  end

  def test_can_check_size_of_empty_file
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << ''
    end
    assert_nil File.size?("file.txt")
  end

  def test_zero_on_empty_file
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << ''
    end
    assert_equal true, File.zero?(path)
  end

  def test_zero_on_non_empty_file
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << 'Not empty'
    end
    assert_equal false, File.zero?(path)
  end

  def test_zero_on_non_existent_file
    path = 'file_does_not_exist.txt'
    assert_equal false, File.zero?(path)
  end

  def test_raises_error_on_mtime_if_file_does_not_exist
    assert_raise Errno::ENOENT do
      File.mtime('/path/to/file.txt')
    end
  end

  def test_can_return_mtime_on_existing_file
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << ''
    end
    assert File.mtime('file.txt').is_a?(Time)
  end

  def test_raises_error_on_ctime_if_file_does_not_exist
    assert_raise Errno::ENOENT do
      File.ctime('file.txt')
    end
  end

  def test_can_return_ctime_on_existing_file
    File.open("foo", "w") { |f| f << "some content" }
    assert File.ctime('foo').is_a?(Time)
  end

  def test_raises_error_on_atime_if_file_does_not_exist
    assert_raise Errno::ENOENT do
      File.atime('file.txt')
    end
  end

  def test_can_return_atime_on_existing_file
    File.open("foo", "w") { |f| f << "some content" }
    assert File.atime('foo').is_a?(Time)
  end

  def test_ctime_mtime_and_atime_are_equal_for_new_files
    FileUtils.touch('foo')

    ctime = File.ctime("foo")
    mtime = File.mtime("foo")
    atime = File.atime("foo")
    assert ctime.is_a?(Time)
    assert mtime.is_a?(Time)
    assert atime.is_a?(Time)
    assert_equal ctime, mtime
    assert_equal ctime, atime

    File.open("foo", "r") do |f|
      assert_equal ctime, f.ctime
      assert_equal mtime, f.mtime
      assert_equal atime, f.atime
    end
  end

  def test_ctime_mtime_and_atime_are_equal_for_new_directories
    FileUtils.mkdir_p("foo")
    ctime = File.ctime("foo")
    mtime = File.mtime("foo")
    atime = File.atime("foo")
    assert ctime.is_a?(Time)
    assert mtime.is_a?(Time)
    assert atime.is_a?(Time)
    assert_equal ctime, mtime
    assert_equal ctime, atime
  end

  def test_file_ctime_is_equal_to_file_stat_ctime
    File.open("foo", "w") { |f| f << "some content" }
    assert_equal File.stat("foo").ctime, File.ctime("foo")
  end

  def test_directory_ctime_is_equal_to_directory_stat_ctime
    FileUtils.mkdir_p("foo")
    assert_equal File.stat("foo").ctime, File.ctime("foo")
  end

  def test_file_mtime_is_equal_to_file_stat_mtime
    File.open("foo", "w") { |f| f << "some content" }
    assert_equal File.stat("foo").mtime, File.mtime("foo")
  end

  def test_directory_mtime_is_equal_to_directory_stat_mtime
    FileUtils.mkdir_p("foo")
    assert_equal File.stat("foo").mtime, File.mtime("foo")
  end

  def test_file_atime_is_equal_to_file_stat_atime
    File.open("foo", "w") { |f| f << "some content" }
    assert_equal File.stat("foo").atime, File.atime("foo")
  end

  def test_directory_atime_is_equal_to_directory_stat_atime
    FileUtils.mkdir_p("foo")
    assert_equal File.stat("foo").atime, File.atime("foo")
  end

  def test_utime_raises_error_if_path_does_not_exist
    assert_raise Errno::ENOENT do
      File.utime(Time.now, Time.now, '/path/to/file.txt')
    end
  end

  def test_can_call_utime_on_an_existing_file
    time = Time.now - 300 # Not now
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f << ''
    end
    File.utime(time, time, path)
    assert_equal time, File.mtime('file.txt')
    assert_equal time, File.atime('file.txt')
  end

  def test_utime_returns_number_of_paths
    path1, path2 = 'file.txt', 'another_file.txt'
    [path1, path2].each do |path|
      File.open(path, 'w') do |f|
        f << ''
      end
    end
    assert_equal 2, File.utime(Time.now, Time.now, path1, path2)
  end

  def test_file_a_time_updated_when_file_is_read
    old_atime = Time.now - 300

    path = "file.txt"
    File.open(path, "w") do |f|
      f << "Hello"
    end

    File.utime(old_atime, File.mtime(path), path)

    assert_equal File.atime(path), old_atime
    File.read(path)
    assert_not_equal File.atime(path), old_atime
  end

  def test_can_read_with_File_readlines
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.puts "Yatta!", "Gatta!"
      f.puts ["woot","toot"]
    end

    assert_equal ["Yatta!\n", "Gatta!\n", "woot\n", "toot\n"], File.readlines(path)
  end

  def test_can_read_with_File_readlines_and_only_empty_lines
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "\n"
    end

    assert_equal ["\n"], File.readlines(path)
  end

  def test_can_read_with_File_readlines_and_new_lines
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "this\nis\na\ntest\n"
    end

    assert_equal ["this\n", "is\n", "a\n", "test\n"], File.readlines(path)
  end

  def test_File_close_disallows_further_access
    path = 'file.txt'
    file = File.open(path, 'w')
    file.write 'Yada'
    file.close
    assert_raise IOError do
      file.read
    end
  end

  def test_File_close_disallows_further_writes
    path = 'file.txt'
    file = File.open(path, 'w')
    file.write 'Yada'
    file.close
    assert_raise IOError do
      file << "foo"
    end
  end

  def test_can_read_from_file_objects
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert_equal "Yatta!", File.new(path).read
  end

  if RUBY_VERSION >= "1.9"
    def test_file_object_has_default_external_encoding
      Encoding.default_external = "UTF-8"
      path = 'file.txt'
      File.open(path, 'w'){|f| f.write 'Yatta!' }
      assert_equal "UTF-8", File.new(path).read.encoding.name
    end
  end

  def test_file_object_initialization_with_mode_in_hash_parameter
    assert_nothing_raised do
      File.open("file.txt", {:mode => "w"}){ |f| f.write 'Yatta!' }
    end
  end

  def test_file_object_initialization_with_brackets_in_filename
    filename = "bracket[1](2).txt"
    expected_contents = "Yokudekimashita"
    assert_nothing_raised do
      File.open(filename, {:mode => "w"}){ |f| f.write "#{expected_contents}" }
    end
    the_file = Dir["/*"]
    assert_equal the_file.length, 1
    assert_equal the_file[0], "/#{filename}"
    contents = File.open("/#{filename}").read()
    assert_equal contents, expected_contents
  end

  def test_file_object_initialization_with_unicode_in_filename
    # 日本語
    filename = "\u65e5\u672c\u8a9e.txt"
    expected_contents = "Yokudekimashita"
    assert_nothing_raised do
      File.open(filename, {:mode => "w"}){ |f| f.write "#{expected_contents}" }
    end
    contents = File.open("/#{filename}").read()
    assert_equal contents, expected_contents
  end

  def test_file_read_errors_appropriately
    assert_raise Errno::ENOENT do
      File.read('anything')
    end
  end

  def test_file_read_errors_on_directory
    FileUtils.mkdir_p("a_directory")

    assert_raise Errno::EISDIR do
      File.read("a_directory")
    end
  end

  def test_knows_files_are_files
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end

    assert File.file?(path)
  end

  def test_File_io_returns_self
    f = File.open("foo", "w")
    assert_equal f, f.to_io
  end

  def test_File_to_i_is_alias_for_filno
    f = File.open("foo", "w")
    assert_equal f.method(:to_i), f.method(:fileno)
  end

  def test_knows_symlink_files_are_files
    path = 'file.txt'
    File.open(path, 'w') do |f|
      f.write "Yatta!"
    end
    FileUtils.ln_s path, sympath='/sympath'

    assert File.file?(sympath)
  end

  def test_knows_non_existent_files_arent_files
    assert_equal RealFile.file?('does/not/exist.txt'), File.file?('does/not/exist.txt')
  end

  def test_executable_returns_false_for_non_existent_files
    assert !File.executable?('/does/not/exist')
  end

  def test_file_utils_cp_allows_verbose_option
    File.open('foo', 'w') {|f| f << 'TEST' }

    std_error = capture_stderr { FileUtils.cp 'foo', 'bar', :verbose => true }
    assert_equal "cp foo bar\n", std_error
  end

  def test_dir_glob_handles_root
    FileUtils.mkdir_p '/path'

    assert_equal ['/'], Dir['/']
  end

  def test_dir_glob_takes_optional_flags
    FileUtils.touch "/foo"
    assert_equal Dir.glob("/*", 0), ["/foo"]
  end

  def test_dir_glob_handles_recursive_globs
    FileUtils.mkdir_p "/one/two/three"
    File.open('/one/two/three/four.rb', 'w')
    File.open('/one/five.rb', 'w')
    assert_equal ['/one/five.rb', '/one/two/three/four.rb'], Dir['/one/**/*.rb']
    assert_equal ['/one/two'], Dir['/one/**/two']
    assert_equal ['/one/two/three'], Dir['/one/**/three']
  end

  def test_dir_recursive_glob_ending_in_wildcards_returns_both_files_and_dirs
    FileUtils.mkdir_p "/one/two/three"
    File.open('/one/two/three/four.rb', 'w')
    File.open('/one/five.rb', 'w')
    assert_equal ['/one/five.rb', '/one/two', '/one/two/three', '/one/two/three/four.rb'], Dir['/one/**/*']
    assert_equal ['/one/five.rb', '/one/two'], Dir['/one/**']
  end

  def test_dir_glob_with_block
    touch_files ['foo', 'bar']

    yielded = []
    Dir.glob('*') { |file| yielded << file }

    assert_equal 2, yielded.size
  end

  if RUBY_VERSION >= "1.9"
    def test_dir_home
      assert_equal RealDir.home, Dir.home
    end
  end

  def test_should_report_pos_as_0_when_opening
    File.open("foo", "w") do |f|
      f << "foobar"
      f.rewind

      assert_equal 0, f.pos
    end
  end

  def test_should_report_pos_as_1_when_seeking_one_char
    File.open("foo", "w") do |f|
      f << "foobar"

      f.rewind
      f.seek(1)

      assert_equal 1, f.pos
    end
  end

  def test_should_set_pos
    File.open("foo", "w") do |f|
      f << "foo"
    end

    fp = File.open("foo", "r")
    fp.pos = 1

    assert_equal 1, fp.pos
  end

  def test_should_set_pos_with_tell_method
    File.open("foo", "w") do |f|
      f << "foo"
    end

    fp = File.open("foo", "r")
    fp.tell = 1

    assert_equal 1, fp.pos
  end

  OMITTED_FILE_METHODS = [
    # omit methods from io/console
    :raw, :raw!, :cooked, :cooked!,
    :echo?, :echo=, :noecho,
    :winsize, :winsize=,
    :getch,
    :iflush, :ioflush, :oflush
  ]

  def test_every_method_in_file_is_in_fake_fs_file
    (RealFile.instance_methods - OMITTED_FILE_METHODS).each do |method_name|
      assert File.instance_methods.include?(method_name), "#{method_name} method is not available in File :("
    end
  end

  def test_file_should_not_respond_to_string_io_unique_methods
    uniq_string_io_methods = StringIO.instance_methods - RealFile.instance_methods
    uniq_string_io_methods.each do |method_name|
      assert !File.instance_methods.include?(method_name), "File responds to #{method_name}"
    end
  end

  def test_does_not_remove_methods_from_stringio
    stringio = StringIO.new("foo")
    assert stringio.respond_to?(:size)
  end

  def test_is_not_a_stringio
    File.open("foo", "w") do |f|
      assert !f.is_a?(StringIO), 'File is not a StringIO'
    end
  end

  def test_chdir_changes_directories_like_a_boss
    FileUtils.mkdir_p '/path'
    assert_equal '/', FileSystem.fs.name
    assert_equal [], Dir.glob('/path/*')
    Dir.chdir '/path' do
      touch_file 'foo'
    end

    assert_equal '/', FileSystem.fs.name
    assert_exists '/path/foo'
  end

  def test_chdir_shouldnt_keep_us_from_absolute_paths
    FileUtils.mkdir_p '/path'

    Dir.chdir '/path' do
      touch_files ['foo', '/foobar']
    end
    assert_exist ['/path/foo', '/foobar', '/path']

    Dir.chdir '/path' do
      FileUtils.rm('foo')
      FileUtils.rm('/foobar')
    end

    assert_equal [], Dir.glob('/path/*').sort
    assert_exist ['/path']
  end

  def test_chdir_should_be_nestable
    FileUtils.mkdir_p '/path/me'
    Dir.chdir '/path' do
      touch_file 'foo'
      Dir.chdir 'me' do
        touch_file 'foobar'
      end
    end

    assert_exist ['/path/foo', '/path/me', '/path/me/foobar']
  end

  def test_chdir_should_be_nestable_with_absolute_paths
    FileUtils.mkdir_p '/path/me'
    Dir.chdir '/path' do
      touch_file 'foo'
      Dir.chdir '/path/me' do
        touch_file 'foobar'
      end
    end

    assert_exist ['/path/foo', '/path/me', '/path/me/foobar']
  end

  def assert_not_exist files
    files.each do |file|
      assert_not_exists file
    end
  end

  def assert_not_exists file
    assert !File.exist?(file)
  end

  def assert_exist files
    files.each do |file|
      assert_exists file
    end
  end

  def assert_exists file
    assert File.exist? file
  end

  def test_chdir_should_flop_over_and_die_if_the_dir_doesnt_exist
    assert_raise(Errno::ENOENT) do
      Dir.chdir('/nope') do
        1
      end
    end
  end

  def test_chdir_with_no_block_is_awesome
    FileUtils.mkdir_p '/path'
    Dir.chdir('/path')
    FileUtils.mkdir_p 'subdir'
    assert_exists 'subdir'
    Dir.chdir('subdir')
    File.open('foo', 'w') { |f| f.write 'foo'}
    assert_exists 'foo'

    assert_raises(Errno::ENOENT) do
      Dir.chdir('subsubdir')
    end

    assert_exists 'foo'
  end

  def test_current_dir_reflected_by_pwd
    FileUtils.mkdir_p '/path'
    Dir.chdir('/path')

    assert_equal '/path', Dir.pwd
    assert_equal '/path', Dir.getwd

    FileUtils.mkdir_p 'subdir'
    Dir.chdir('subdir')

    assert_equal '/path/subdir', Dir.pwd
    assert_equal '/path/subdir', Dir.getwd
  end

  def test_current_dir_reflected_by_expand_path_with_relative_paths
    FileUtils.mkdir_p '/path'
    Dir.chdir '/path'

    assert_equal '/path', File.expand_path('.')
    assert_equal '/path/foo', File.expand_path('foo')

    FileUtils.mkdir_p 'subdir'
    Dir.chdir 'subdir'

    assert_equal '/path/subdir', File.expand_path('.')
    assert_equal '/path/subdir/foo', File.expand_path('foo')
  end

  def test_expand_path_with_parent_dir
    FakeFS.deactivate!
    real = File.expand_path('../other.file',__FILE__)
    FakeFS.activate!
    fake = File.expand_path('../other.file',__FILE__)
    assert_equal real, fake
  end

  def test_expand_path_works_with_absolute_paths
    FakeFS.deactivate!
    home = File.expand_path('~')
    FakeFS.activate!
    assert_equal "#{home}/dir/subdir", File.expand_path('subdir', '~/dir')
    assert_equal '/somewhere/else', File.expand_path('else', '/somewhere')
  end

  def test_file_open_defaults_to_read
    File.open('foo','w') { |f| f.write 'bar' }
    assert_equal 'bar', File.open('foo') { |f| f.read }
  end

  def test_flush_exists_on_file
    r = File.open('foo','w') { |f| f.write 'bar';  f.flush }
    assert_equal 'foo', r.path
  end

  def test_clone_clones_normal_files
    RealFile.open(here('foo'), 'w') { |f| f.write 'bar' }
    assert !File.exists?(here('foo'))
    FileSystem.clone(here('foo'))
    assert_equal 'bar', File.open(here('foo')) { |f| f.read }
  ensure
    RealFile.unlink(here('foo')) if RealFile.exists?(here('foo'))
  end

  def test_clone_clones_directories
    act_on_real_fs { RealFileUtils.mkdir_p(here('subdir')) }

    FileSystem.clone(here('subdir'))

    assert File.exists?(here('subdir')), 'subdir was cloned'
    assert File.directory?(here('subdir')), 'subdir is a directory'
  ensure
    act_on_real_fs { RealFileUtils.rm_rf(here('subdir')) }
  end

  def test_clone_clones_dot_files_even_hard_to_find_ones
    act_on_real_fs { RealFileUtils.mkdir_p(here('subdir/.bar/baz/.quux/foo')) }

    assert !File.exists?(here('subdir'))

    FileSystem.clone(here('subdir'))
    assert_equal ['.', '..', '.bar'], Dir.entries(here('subdir'))
    assert_equal ['.', '..', 'foo'], Dir.entries(here('subdir/.bar/baz/.quux'))
  ensure
    act_on_real_fs { RealFileUtils.rm_rf(here('subdir')) }
  end

  def test_dir_glob_on_clone_with_absolute_path
    act_on_real_fs { RealFileUtils.mkdir_p(here('subdir/.bar/baz/.quux/foo')) }
    FileUtils.mkdir_p '/path'
    Dir.chdir('/path')
    FileSystem.clone(here('subdir'), "/foo")
    assert Dir.glob "/foo/*"
  ensure
    act_on_real_fs { RealFileUtils.rm_rf(here('subdir')) }
  end

  def test_clone_with_target_specified
    act_on_real_fs { RealFileUtils.mkdir_p(here('subdir/.bar/baz/.quux/foo')) }

    assert !File.exists?(here('subdir'))

    FileSystem.clone(here('subdir'), here('subdir2'))
    assert !File.exists?(here('subdir'))
    assert_equal ['.', '..', '.bar'], Dir.entries(here('subdir2'))
    assert_equal ['.', '..', 'foo'], Dir.entries(here('subdir2/.bar/baz/.quux'))
  ensure
    act_on_real_fs { RealFileUtils.rm_rf(here('subdir')) }
  end

  def test_clone_with_file_symlinks
    original = here('subdir/test-file')
    symlink  = here('subdir/test-file.txt')

    act_on_real_fs do
      RealDir.mkdir(RealFile.dirname(original))
      RealFile.open(original, 'w') {|f| f << 'stuff' }
      RealFileUtils.ln_s original, symlink
      assert RealFile.symlink?(symlink), 'real symlink is in place'
    end

    assert !File.exists?(original), 'file does not already exist'

    FileSystem.clone(File.dirname(original))
    assert File.symlink?(symlink), 'symlinks are cloned as symlinks'
    assert_equal 'stuff', File.read(symlink)
  ensure
    act_on_real_fs { RealFileUtils.rm_rf File.dirname(original) }
  end

  def test_clone_with_dir_symlinks
    original = here('subdir/dir')
    symlink  = here('subdir/dir.link')
    original_file = File.join(original, 'test-file')
    symlink_file  = File.join(symlink, 'test-file')

    act_on_real_fs do
      RealFileUtils.mkdir_p(original)
      RealFile.open(original_file, 'w') {|f| f << 'stuff' }
      RealFileUtils.ln_s original, symlink
      assert RealFile.symlink?(symlink), 'real symlink is in place'
    end

    assert !File.exists?(original_file), 'file does not already exist'

    FileSystem.clone(File.dirname(original))
    assert File.symlink?(symlink), 'symlinks are cloned as symlinks'
    assert_equal 'stuff', File.read(symlink_file)
  ensure
    act_on_real_fs { RealFileUtils.rm_rf File.dirname(original) }
  end

  def test_file_can_read_from_symlinks
    File.open('first', 'w') { |f| f.write '1'}
    FileUtils.ln_s 'first', 'one'
    assert_equal '1', File.open('one') { |f| f.read }

    FileUtils.mkdir_p 'subdir'
    File.open('subdir/nother','w') { |f| f.write 'works' }
    FileUtils.ln_s 'subdir', 'new'
    assert_equal 'works', File.open('new/nother') { |f| f.read }
  end

  def test_can_symlink_through_file
    FileUtils.touch("/foo")

    File.symlink("/foo", "/bar")

    assert File.symlink?("/bar")
  end

  def test_extname
    assert_equal File.extname("test.doc"), ".doc"
  end

  def test_rename_renames_a_file
    FileUtils.touch("/foo")
    File.rename("/foo", "/bar")
    assert File.file?("/bar")
  end

  def test_rename_returns
    FileUtils.touch("/foo")
    assert_equal 0, File.rename("/foo", "/bar")
  end

  def test_rename_renames_two_files
    FileUtils.touch("/foo")
    FileUtils.touch("/bar")
    File.rename("/foo", "/bar")
    assert File.file?("/bar")
  end

  def test_rename_renames_a_directories
    Dir.mkdir("/foo")
    File.rename("/foo", "/bar")
    assert File.directory?("/bar")
  end

  def test_rename_renames_two_directories
    Dir.mkdir("/foo")
    Dir.mkdir("/bar")
    File.rename("/foo", "/bar")
    assert File.directory?("/bar")
  end

  def test_rename_file_to_directory_raises_error
    FileUtils.touch("/foo")
    Dir.mkdir("/bar")
    assert_raises(Errno::EISDIR) do
      File.rename("/foo", "/bar")
    end
  end

  def test_rename_directory_to_file_raises_error
    Dir.mkdir("/foo")
    FileUtils.touch("/bar")
    assert_raises(Errno::ENOTDIR) do
      File.rename("/foo", "/bar")
    end
  end


  def test_rename_with_missing_source_raises_error
    assert_raises(Errno::ENOENT) do
      File.rename("/no_such_file", "/bar")
    end
  end

  def test_rename_with_missing_dest_directory_raises_error
    FileUtils.touch("/foo")
    assert_raises(Errno::ENOENT) do
      File.rename("/foo", "/bar/foo")
    end
  end

  def test_hard_link_creates_file
    FileUtils.touch("/foo")

    File.link("/foo", "/bar")
    assert File.exists?("/bar")
  end

  def test_hard_link_with_missing_file_raises_error
    assert_raises(Errno::ENOENT) do
      File.link("/foo", "/bar")
    end
  end

  def test_hard_link_with_existing_destination_file
    FileUtils.touch("/foo")
    FileUtils.touch("/bar")

    assert_raises(Errno::EEXIST) do
      File.link("/foo", "/bar")
    end
  end

  def test_hard_link_returns_0_when_successful
    FileUtils.touch("/foo")

    assert_equal 0, File.link("/foo", "/bar")
  end

  def test_hard_link_returns_duplicate_file
    File.open("/foo", "w") { |x| x << "some content" }

    File.link("/foo", "/bar")
    assert_equal "some content", File.read("/bar")
  end

  def test_hard_link_with_directory_raises_error
    Dir.mkdir "/foo"

    assert_raises(Errno::EPERM) do
      File.link("/foo", "/bar")
    end
  end

  def test_can_delete_file_with_delete
    FileUtils.touch("/foo")

    File.delete("/foo")

    assert_not_exists '/foo'
  end

  def test_can_delete_multiple_files_with_delete
    FileUtils.touch("/foo")
    FileUtils.touch("/bar")

    File.delete("/foo", "/bar")

    assert_not_exist ['/foo', '/bar']
  end

  def test_delete_returns_zero_when_no_filename_given
    assert_equal 0, File.delete
  end

  def test_delete_returns_number_one_when_given_one_arg
    FileUtils.touch("/foo")

    assert_equal 1, File.delete("/foo")
  end

  def test_delete_returns_number_two_when_given_two_args
    FileUtils.touch("/foo")
    FileUtils.touch("/bar")

    assert_equal 2, File.delete("/foo", "/bar")
  end

  def test_delete_raises_error_when_first_file_does_not_exist
    assert_raises Errno::ENOENT do
      File.delete("/foo")
    end
  end

  def test_unlink_removes_only_one_file_content
    File.open("/foo", "w") { |f| f << "some_content" }
    File.link("/foo", "/bar")

    File.unlink("/bar")
    assert_equal "some_content", File.read("/foo")
  end

  def test_link_reports_correct_stat_info_after_unlinking
    File.open("/foo", "w") { |f| f << "some_content" }
    File.link("/foo", "/bar")

    File.unlink("/bar")
    assert_equal 1, File.stat("/foo").nlink
  end

  def test_delete_works_with_symlink
    FileUtils.touch("/foo")
    File.symlink("/foo", "/bar")

    File.unlink("/bar")

    assert_not_exists '/bar'
    assert_exists '/foo'
  end

  def test_delete_works_with_symlink_source
    FileUtils.touch("/foo")
    File.symlink("/foo", "/bar")

    File.unlink("/foo")

    assert_not_exists '/foo'
  end

  def test_file_seek_returns_0
    File.open("/foo", "w") do |f|
      f << "one\ntwo\nthree"
    end

    file = File.open("/foo", "r")

    assert_equal 0, file.seek(1)
  end

  def test_file_seek_seeks_to_location
    File.open("/foo", "w") do |f|
      f << "123"
    end

    file = File.open("/foo", "r")
    file.seek(1)
    assert_equal "23", file.read
  end

  def test_file_seek_seeks_to_correct_location
    File.open("/foo", "w") do |f|
      f << "123"
    end

    file = File.open("/foo", "r")
    file.seek(2)
    assert_equal "3", file.read
  end

  def test_file_seek_can_take_negative_offset
    File.open("/foo", "w") do |f|
      f << "123456789"
    end

    file = File.open("/foo", "r")

    file.seek(-1, IO::SEEK_END)
    assert_equal "9", file.read

    file.seek(-2, IO::SEEK_END)
    assert_equal "89", file.read

    file.seek(-3, IO::SEEK_END)
    assert_equal "789", file.read
  end

  def test_should_have_constants_inherited_from_descending_from_io
    assert_equal IO::SEEK_CUR, File::SEEK_CUR
    assert_equal IO::SEEK_END, File::SEEK_END
    assert_equal IO::SEEK_SET, File::SEEK_SET
  end

  def test_filetest_exists_return_correct_values
    FileUtils.mkdir_p("/path/to/dir")
    assert FileTest.exist?("/path/to/")

    FileUtils.rmdir("/path/to/dir")
    assert !FileTest.exist?("/path/to/dir")
  end

  def test_filetest_directory_returns_correct_values
    FileUtils.mkdir_p '/path/to/somedir'
    assert FileTest.directory?('/path/to/somedir')

    FileUtils.rm_r '/path/to/somedir'
    assert !FileTest.directory?('/path/to/somedir')
  end

  def test_filetest_file_returns_correct_values
    FileUtils.mkdir_p("/path/to")

    path = '/path/to/file.txt'
    File.open(path, 'w') { |f| f.write "Yatta!" }
    assert FileTest.file?(path)

    FileUtils.rm path
    assert !FileTest.file?(path)

    FileUtils.mkdir_p '/path/to/somedir'
    assert !FileTest.file?('/path/to/somedir')
  end

  def test_filetest_writable_returns_correct_values
    assert !FileTest.writable?('not-here.txt'), 'missing files are not writable'

    FileUtils.touch 'here.txt'
    assert FileTest.writable?('here.txt'), 'existing files are writable'

    FileUtils.mkdir 'dir'
    assert FileTest.writable?('dir'), 'directories are writable'
  end

  def test_pathname_exists_returns_correct_value
    FileUtils.touch "foo"
    assert Pathname.new("foo").exist?

    assert !Pathname.new("bar").exist?
  end

  def test_pathname_method_is_faked
    FileUtils.mkdir_p '/path'
    assert Pathname('/path').exist?, 'Pathname() method is faked'
  end

  def test_dir_mktmpdir
    FileUtils.mkdir '/tmp'

    tmpdir = Dir.mktmpdir
    assert File.directory?(tmpdir)
    FileUtils.rm_r tmpdir

    Dir.mktmpdir do |t|
      tmpdir = t
      assert File.directory?(t)
    end
    assert !File.directory?(tmpdir)
  end

  def test_activating_returns_true
    FakeFS.deactivate!
    assert_equal true, FakeFS.activate!
  end

  def test_deactivating_returns_true
    assert_equal true, FakeFS.deactivate!
  end

  def test_split
    assert File.respond_to? :split
    filename = "/this/is/what/we/expect.txt"
    path,filename = File.split(filename)
    assert_equal path, "/this/is/what/we"
    assert_equal filename, "expect.txt"
  end

  #########################
  def test_file_default_mode
    FileUtils.touch "foo"
    assert_equal File.stat("foo").mode, (0100000 + 0666 - File.umask)
  end

  def test_dir_default_mode
    Dir.mkdir "bar"
    assert_equal File.stat("bar").mode, (0100000 + 0777 - File.umask)
  end

  def test_file_default_uid_and_gid
    FileUtils.touch "foo"
    assert_equal File.stat("foo").uid, Process.uid
    assert_equal File.stat("foo").gid, Process.gid
  end

  def test_file_chmod_of_file
    FileUtils.touch "foo"
    File.chmod 0600, "foo"
    assert_equal File.stat("foo").mode, 0100600
    File.new("foo").chmod 0644
    assert_equal File.stat("foo").mode, 0100644
  end

  def test_file_chmod_of_dir
    Dir.mkdir "bar"
    File.chmod 0777, "bar"
    assert_equal File.stat("bar").mode, 0100777
    File.new("bar").chmod 01700
    assert_equal File.stat("bar").mode, 0101700
  end

  def test_file_chown_of_file
    FileUtils.touch "foo"
    File.chown 1337, 1338, "foo"
    assert_equal File.stat("foo").uid, 1337
    assert_equal File.stat("foo").gid, 1338
  end

  def test_file_chown_of_dir
    Dir.mkdir "bar"
    File.chown 1337, 1338, "bar"
    assert_equal File.stat("bar").uid, 1337
    assert_equal File.stat("bar").gid, 1338
  end

  def test_file_chown_of_file_nil_user_group
    FileUtils.touch "foo"
    File.chown 1337, 1338, "foo"
    File.chown nil, nil, "foo"
    assert_equal File.stat("foo").uid, 1337
    assert_equal File.stat("foo").gid, 1338
  end

  def test_file_chown_of_file_negative_user_group
    FileUtils.touch "foo"
    File.chown 1337, 1338, "foo"
    File.chown -1, -1, "foo"
    assert_equal File.stat("foo").uid, 1337
    assert_equal File.stat("foo").gid, 1338
  end

  def test_file_instance_chown_nil_user_group
    FileUtils.touch('foo')
    File.chown(1337, 1338, 'foo')
    assert_equal File.stat('foo').uid, 1337
    assert_equal File.stat('foo').gid, 1338
    file = File.open('foo')
    file.chown nil, nil
    assert_equal File.stat('foo').uid, 1337
    assert_equal File.stat('foo').gid, 1338
  end

  def test_file_instance_chown_negative_user_group
    FileUtils.touch('foo')
    File.chown(1337, 1338, 'foo')
    assert_equal File.stat('foo').uid, 1337
    assert_equal File.stat('foo').gid, 1338
    file = File.new('foo')
    file.chown -1, -1
    file.close
    assert_equal File.stat('foo').uid, 1337
    assert_equal File.stat('foo').gid, 1338
  end

  def test_file_umask
    assert_equal File.umask, RealFile.umask
    File.umask(0740)

    assert_equal File.umask, RealFile.umask
    assert_equal File.umask, 0740
  end

  def test_file_binread_works
    File.open("testfile", 'w') do |f|
      f << "This is line one\nThis is line two\nThis is line three\nAnd so on...\n"
    end

    assert_equal File.binread("testfile"), "This is line one\nThis is line two\nThis is line three\nAnd so on...\n"
    assert_equal File.binread("testfile", 20), "This is line one\nThi"
    assert_equal File.binread("testfile", 20, 10), "ne one\nThis is line "
  end

  def here(fname)
    RealFile.expand_path(File.join(RealFile.dirname(__FILE__), fname))
  end

  if RUBY_VERSION >= "1.9.1"
    def test_absolute_path_with_absolute_path
      assert_equal '/foo/bar', File.absolute_path('/foo/bar')
    end

    def test_absolute_path_with_absolute_path_with_dir_name
      assert_equal '/foo/bar', File.absolute_path('/foo/bar', '/dir')
    end

    def test_absolute_path_with_relative_path
      assert_equal "#{Dir.getwd}foo/bar", File.absolute_path('foo/bar')
    end

    def test_absolute_path_with_relative_path_with_dir_name
      assert_equal "/dir/foo/bar", File.absolute_path('foo/bar', '/dir')
    end
  end


  if RUBY_VERSION >= "1.9.2"
    def test_file_size
      File.open("foo", 'w') do |f|
        f << 'Yada Yada'
        assert_equal 9, f.size
      end
    end

    def test_fdatasync
      File.open("foo", 'w') do |f|
        f << 'Yada Yada'
        assert_nothing_raised do
          f.fdatasync
        end
      end
    end

    def test_autoclose
      File.open("foo", 'w') do |f|
        assert_equal true, f.autoclose?
        f.autoclose = false
        assert_equal false, f.autoclose?
      end
    end

    def test_to_path
      File.new("foo", 'w') do |f|
        assert_equal "foo", f.to_path
      end
    end
  end

  if RUBY_VERSION >= "1.9.3"
    def test_advise
      File.open("foo", 'w') do |f|
        assert_nothing_raised do
          f.advise(:normal, 0, 0)
        end
      end
    end

    def test_file_read_respects_hashes
      path = 'file.txt'
      File.open(path, 'w') do |f|
        f.write 'Yatta!'
      end

      assert_equal 'ASCII-8BIT', File.read(path, :mode => 'rb').encoding.to_s
    end

    def test_file_read_respects_args_and_hashes
      path = 'file.txt'
      File.open(path, 'w') do |f|
        f.write 'Yatta!'
      end

      result = File.read(path, 2, 1, :mode => 'rb')
      assert_equal 'at', result
      assert_equal 'ASCII-8BIT', result.encoding.to_s
    end

    def test_file_write_can_write_a_file
      File.write("testfile", "0123456789")
      assert_equal File.read("testfile"), "0123456789"
    end

    def test_file_write_returns_the_length_written
      assert_equal File.write("testfile", "0123456789"), 10
    end

    def test_file_write_truncates_file_if_offset_not_given
      File.open("foo", 'w') do |f|
        f << "foo"
      end

      File.write('foo', 'bar')
      assert_equal File.read('foo'), 'bar'
    end

    def test_file_write_writes_at_offset_and_does_not_truncate
      File.open("foo", 'w') do |f|
        f << "foo"
      end

      File.write('foo', 'bar', 3)
      assert_equal File.read('foo'), 'foobar'
    end

    def test_can_read_binary_data_in_binary_mode
      File.open('foo', 'wb') { |f| f << sample_string_unicode }

      contents = File.open("foo", "rb").read
      assert_equal sample_string_binary.force_encoding('ASCII-8BIT'), contents
    end

    def test_can_read_binary_data_in_non_binary_mode
      File.open('foo_non_bin', 'wb') { |f| f << sample_string_unicode }

      contents = File.open("foo_non_bin", "r").read
      assert_equal sample_string_binary.force_encoding('UTF-8'), contents
    end

    def test_can_read_binary_data_using_binread
      File.open('foo', 'wb') { |f| f << sample_string_unicode }

      contents = File.binread("foo")
      assert_equal sample_string_binary.force_encoding('ASCII-8BIT'), contents
    end

    def sample_string_unicode
      "\u0000\u0000\u0000\u0003\u0000\u0003\u0000\xA3"+
        "\u0000\u0000\u0000y\u0000\u0000\u0000\u0000\u0000"
    end

    def sample_string_binary
      "\x00\x00\x00\x03\x00\x03\x00\xA3\x00\x00\x00y\x00\x00\x00\x00\x00"
    end
  end
end
