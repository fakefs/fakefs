# -*- coding: utf-8 -*-
require "test_helper"

class FileUtilsTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_can_create_directories_with_file_utils_mkdir_p
    FileUtils.mkdir_p("/path/to/dir")
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_can_cd_to_directory_with_block
    FileUtils.mkdir_p("/path/to/dir")
    new_path = nil
    FileUtils.cd("/path/to") do
      new_path = Dir.getwd
    end

    assert_equal new_path, "/path/to"
  end

  def test_can_create_a_list_of_directories_with_file_utils_mkdir_p
    FileUtils.mkdir_p(["/path/to/dir1", "/path/to/dir2"])
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir1']
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir2']
  end

  def test_can_create_directories_with_options
    FileUtils.mkdir_p("/path/to/dir", :mode => 0755)
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_can_create_directories_with_file_utils_mkdir
    FileUtils.mkdir_p("/path/to/dir")
    FileUtils.mkdir("/path/to/dir/subdir")
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']['subdir']
  end

  def test_can_create_a_list_of_directories_with_file_utils_mkdir
    FileUtils.mkdir_p("/path/to/dir")
    FileUtils.mkdir(["/path/to/dir/subdir1", "/path/to/dir/subdir2"])
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']['subdir1']
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']['subdir2']
  end

  def test_raises_error_when_creating_a_new_dir_with_mkdir_in_non_existent_path
    assert_raises Errno::ENOENT do
      FileUtils.mkdir("/this/path/does/not/exists/newdir")
    end
  end

  def test_raises_error_when_creating_a_new_dir_over_existing_file
    File.open("file", "w") {|f| f << "This is a file, not a directory." }

    assert_raise Errno::EEXIST do
      FileUtils.mkdir_p("file/subdir")
    end

    FileUtils.mkdir("dir")
    File.open("dir/subfile", "w") {|f| f << "This is a file inside a directory." }

    assert_raise Errno::EEXIST do
      FileUtils.mkdir_p("dir/subfile/subdir")
    end
  end

  def test_can_create_directories_with_mkpath
    FileUtils.mkpath("/path/to/dir")
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_can_create_directories_with_mkpath_and_options
    FileUtils.mkpath("/path/to/dir", :mode => 0755)
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_can_create_directories_with_mkdirs
    FileUtils.makedirs("/path/to/dir")
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_can_create_directories_with_mkdirs_and_options
    FileUtils.makedirs("/path/to/dir", :mode => 0755)
    assert_kind_of FakeDir, FileSystem.fs['path']['to']['dir']
  end

  def test_unlink_errors_on_file_not_found
    assert_raise Errno::ENOENT do
      FileUtils.rm("/foo")
    end
  end

  def test_unlink_doesnt_error_on_file_not_found_when_forced
    assert_nothing_raised do
      FileUtils.rm("/foo", :force => true)
    end
  end

  def test_can_delete_directories
    FileUtils.mkdir_p("/path/to/dir")
    FileUtils.rmdir("/path/to/dir")
    assert File.exists?("/path/to/")
    assert_equal File.exists?("/path/to/dir"), false
  end

  def test_can_delete_multiple_files
    FileUtils.touch(["foo", "bar"])
    FileUtils.rm(["foo", "bar"])
    assert_equal File.exists?("foo"), false
    assert_equal File.exists?("bar"), false
  end

  def test_aliases_exist
    assert File.respond_to?(:unlink)
    assert FileUtils.respond_to?(:rm_f)
    assert FileUtils.respond_to?(:rm_r)
    assert FileUtils.respond_to?(:rm)
    assert FileUtils.respond_to?(:rm_rf)
    assert FileUtils.respond_to?(:symlink)
    assert FileUtils.respond_to?(:move)
    assert FileUtils.respond_to?(:copy)
    assert FileUtils.respond_to?(:remove)
    assert FileUtils.respond_to?(:rmtree)
    assert FileUtils.respond_to?(:safe_unlink)
    assert FileUtils.respond_to?(:remove_entry_secure)
    assert FileUtils.respond_to?(:cmp)
    assert FileUtils.respond_to?(:identical?)
  end

  def test_knows_directories_exist
    FileUtils.mkdir_p(path = "/path/to/dir")
    assert File.exists?(path)
  end

  def test_knows_directories_are_directories
    FileUtils.mkdir_p(path = "/path/to/dir")
    assert File.directory?(path)
  end

  def test_knows_directories_are_directories_with_periods
    FileUtils.mkdir_p(period_path = "/path/to/periodfiles/one.one")
    FileUtils.mkdir("/path/to/periodfiles/one-one")

    assert File.directory?(period_path)
  end

  def test_knows_symlink_directories_are_directories
    FileUtils.mkdir_p(path = "/path/to/dir")
    FileUtils.ln_s path, sympath = '/sympath'
    assert File.directory?(sympath)
  end

  def test_knows_non_existent_directories_arent_directories
    path = 'does/not/exist/'
    assert_equal RealFile.directory?(path), File.directory?(path)
  end

  def test_doesnt_overwrite_existing_directories
    FileUtils.mkdir_p(path = "/path/to/dir")
    assert File.exists?(path)
    FileUtils.mkdir_p("/path/to")
    assert File.exists?(path)
    assert_raises Errno::EEXIST do
      FileUtils.mkdir("/path/to")
    end
    assert File.exists?(path)
  end

  def test_file_utils_mkdir_takes_options
    FileUtils.mkdir("/foo", :some => :option)
    assert File.exists?("/foo")
  end

  def test_can_create_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, "/path/to/link")
    assert_kind_of FakeSymlink, FileSystem.fs['path']['to']['link']

    assert_raises(Errno::EEXIST) do
      FileUtils.ln_s(target, '/path/to/link')
    end
  end

  def test_can_force_creation_of_symlinks
    FileUtils.mkdir_p(target = "/path/to/first/target")
    FileUtils.ln_s(target, "/path/to/link")
    assert_kind_of FakeSymlink, FileSystem.fs['path']['to']['link']
    FileUtils.ln_s(target, '/path/to/link', :force => true)
  end

  def test_create_symlink_using_ln_sf
    FileUtils.mkdir_p(target = "/path/to/first/target")
    FileUtils.ln_s(target, "/path/to/link")
    assert_kind_of FakeSymlink, FileSystem.fs['path']['to']['link']
    FileUtils.ln_sf(target, '/path/to/link')
  end

  def test_can_follow_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, link = "/path/to/symlink")
    assert_equal target, File.readlink(link)
  end

  def test_symlinks_in_different_directories
    FileUtils.mkdir_p("/path/to/bar")
    FileUtils.mkdir_p(target = "/path/to/foo/target")

    FileUtils.ln_s(target, link = "/path/to/bar/symlink")
    assert_equal target, File.readlink(link)
  end

  def test_symlink_with_relative_path_exists
    FileUtils.touch("/file")
    FileUtils.mkdir_p("/a/b")
    FileUtils.ln_s("../../file", link = "/a/b/symlink")
    assert File.exist?('/a/b/symlink')
  end

  def test_symlink_with_relative_path_and_nonexistant_file_does_not_exist
    FileUtils.touch("/file")
    FileUtils.mkdir_p("/a/b")
    FileUtils.ln_s("../../file_foo", link = "/a/b/symlink")
    assert !File.exist?('/a/b/symlink')
  end

  def test_symlink_with_relative_path_has_correct_target
    FileUtils.touch("/file")
    FileUtils.mkdir_p("/a/b")
    FileUtils.ln_s("../../file", link = "/a/b/symlink")
    assert_equal "../../file", File.readlink(link)
  end

  def test_symlinks_to_symlinks
    FileUtils.mkdir_p(target = "/path/to/foo/target")
    FileUtils.mkdir_p("/path/to/bar")
    FileUtils.mkdir_p("/path/to/bar2")

    FileUtils.ln_s(target, link1 = "/path/to/bar/symlink")
    FileUtils.ln_s(link1, link2 = "/path/to/bar2/symlink")
    assert_equal link1, File.readlink(link2)
  end

  def test_symlink_to_symlinks_should_raise_error_if_dir_doesnt_exist
    FileUtils.mkdir_p(target = "/path/to/foo/target")

    assert !Dir.exists?("/path/to/bar")

    assert_raise Errno::ENOENT do
      FileUtils.ln_s(target, "/path/to/bar/symlink")
    end
  end

  def test_knows_symlinks_are_symlinks
    FileUtils.mkdir_p(target = "/path/to/target")
    FileUtils.ln_s(target, link = "/path/to/symlink")
    assert File.symlink?(link)
  end

  if RUBY_VERSION >= "1.9"
    def test_can_set_mtime_on_new_file_touch_with_param
      time = Time.new(2002, 10, 31, 2, 2, 2, "+02:00")
      FileUtils.touch("foo.txt", :mtime => time)

      assert_equal File.mtime("foo.txt"), time
    end

    def test_can_set_mtime_on_existing_file_touch_with_param
      FileUtils.touch("foo.txt")

      time = Time.new(2002, 10, 31, 2, 2, 2, "+02:00")
      FileUtils.touch("foo.txt", :mtime => time)

      assert_equal File.mtime("foo.txt"), time
    end
  end

  def test_file_utils_cp_allows_noop_option
    File.open('foo', 'w') {|f| f << 'TEST' }
    FileUtils.cp 'foo', 'bar', :noop => true
    assert !File.exist?('bar'), 'does not actually copy'
  end

  def test_file_utils_cp_raises_on_invalid_option
    assert_raises ArgumentError do
      FileUtils.cp 'foo', 'bar', :whatisthis => "I don't know"
    end
  end

  def test_file_utils_cp_r_allows_verbose_option
    FileUtils.touch "/foo"
    assert_equal "cp -r /foo /bar\n", capture_stderr { FileUtils.cp_r '/foo', '/bar', :verbose => true }
  end

  def test_file_utils_cp_r_allows_noop_option
    FileUtils.touch "/foo"
    FileUtils.cp_r '/foo', '/bar', :noop => true
    assert !File.exist?('/bar'), 'does not actually copy'
  end

  def test_copy_with_subdirectory
    FileUtils.mkdir_p "/one/two/three/"
    FileUtils.mkdir_p "/onebis/two/three/"
    FileUtils.touch "/one/two/three/foo"
    Dir.glob("/one/two/three/*") do |hook|
      FileUtils.cp(hook, "/onebis/two/three/")
    end
    assert_equal ['/onebis/two/three/foo'], Dir['/onebis/two/three/*']
  end

  def test_mv_should_raise_error_on_missing_file
    assert_raise(Errno::ENOENT) do
      FileUtils.mv 'blafgag', 'foo'
    end
    exception = assert_raise(Errno::ENOENT) do
      FileUtils.mv ['foo', 'bar'], 'destdir'
    end
    assert_equal "No such file or directory - foo", exception.message
  end

  def test_mv_actually_works
    File.open('foo', 'w') { |f| f.write 'bar' }
    FileUtils.mv 'foo', 'baz'
    assert_equal 'bar', File.open('baz') { |f| f.read }
  end

  def test_mv_overwrites_existing_files
    File.open('foo', 'w') { |f| f.write 'bar' }
    File.open('baz', 'w') { |f| f.write 'qux' }
    FileUtils.mv 'foo', 'baz'
    assert_equal 'bar', File.read('baz')
  end

  def test_mv_works_with_options
    File.open('foo', 'w') {|f| f.write 'bar'}
    FileUtils.mv 'foo', 'baz', :force => true
    assert_equal('bar', File.open('baz') { |f| f.read })
  end

  def test_mv_to_directory
    File.open('foo', 'w') {|f| f.write 'bar'}
    FileUtils.mkdir_p 'destdir'
    FileUtils.mv 'foo', 'destdir'
    assert_equal('bar', File.open('destdir/foo') {|f| f.read })
    assert File.directory?('destdir')
  end

  def test_mv_array
    File.open('foo', 'w') {|f| f.write 'bar' }
    File.open('baz', 'w') {|f| f.write 'binky' }
    FileUtils.mkdir_p 'destdir'
    FileUtils.mv %w(foo baz), 'destdir'
    assert_equal('bar', File.open('destdir/foo') {|f| f.read })
    assert_equal('binky', File.open('destdir/baz') {|f| f.read })
  end

  def test_mv_accepts_verbose_option
    FileUtils.touch 'foo'
    assert_equal "mv foo bar\n", capture_stderr { FileUtils.mv 'foo', 'bar', :verbose => true }
  end

  def test_mv_accepts_noop_option
    FileUtils.touch 'foo'
    FileUtils.mv 'foo', 'bar', :noop => true
    assert File.exist?('foo'), 'does not remove src'
    assert !File.exist?('bar'), 'does not create target'
  end

  def test_mv_raises_when_moving_file_onto_directory
    FileUtils.mkdir_p 'dir/stuff'
    FileUtils.touch 'stuff'
    assert_raises Errno::EEXIST do
      FileUtils.mv 'stuff', 'dir'
    end
  end

  def test_mv_raises_when_moving_to_non_existent_directory
    FileUtils.touch 'stuff'
    assert_raises Errno::ENOENT do
      FileUtils.mv 'stuff', '/this/path/is/not/here'
    end
  end

  def test_mv_ignores_failures_when_using_force
    FileUtils.mkdir_p 'dir/stuff'
    FileUtils.touch %w[stuff other]
    FileUtils.mv %w[stuff other], 'dir', :force => true
    assert File.exist?('stuff'), 'failed move remains where it was'
    assert File.exist?('dir/other'), 'successful one is moved'
    assert !File.exist?('other'), 'successful one is moved'

    FileUtils.mv 'stuff', '/this/path/is/not/here', :force => true
    assert File.exist?('stuff'), 'failed move remains where it was'
    assert !File.exist?('/this/path/is/not/here'), 'nothing is created for a failed move'
  end

  def test_cp_actually_works
    File.open('foo', 'w') {|f| f.write 'bar' }
    FileUtils.cp('foo', 'baz')
    assert_equal 'bar', File.read('baz')
  end

  def test_cp_file_into_dir
    File.open('foo', 'w') {|f| f.write 'bar' }
    FileUtils.mkdir_p 'baz'

    FileUtils.cp('foo', 'baz')
    assert_equal 'bar', File.read('baz/foo')
  end

  def test_cp_array_of_files_into_directory
    File.open('foo', 'w') { |f| f.write 'footext' }
    File.open('bar', 'w') { |f| f.write 'bartext' }
    FileUtils.mkdir_p 'destdir'
    FileUtils.cp(%w(foo bar), 'destdir')

    assert_equal 'footext', File.read('destdir/foo')
    assert_equal 'bartext', File.read('destdir/bar')
  end

  def test_cp_fails_on_array_of_files_into_non_directory
    File.open('foo', 'w') { |f| f.write 'footext' }

    exception = assert_raise(Errno::ENOTDIR) do
      FileUtils.cp(%w(foo), 'baz')
    end
    assert_equal "Not a directory - baz", exception.to_s
  end

  def test_cp_overwrites_dest_file
    File.open('foo', 'w') {|f| f.write 'FOO' }
    File.open('bar', 'w') {|f| f.write 'BAR' }

    FileUtils.cp('foo', 'bar')
    assert_equal 'FOO', File.read('bar')
  end

  def test_cp_fails_on_no_source
    assert_raise Errno::ENOENT do
      FileUtils.cp('foo', 'baz')
    end
  end

  def test_cp_fails_on_directory_copy
    FileUtils.mkdir_p 'baz'

    assert_raise Errno::EISDIR do
      FileUtils.cp('baz', 'bar')
    end
  end

  def test_copy_file_works
    File.open('foo', 'w') {|f| f.write 'bar' }
    FileUtils.copy_file('foo', 'baz', :ignore_param_1, :ignore_param_2)
    assert_equal 'bar', File.read('baz')
  end

  def test_cp_r_doesnt_tangle_files_together
    File.open('foo', 'w') { |f| f.write 'bar' }
    FileUtils.cp_r('foo', 'baz')
    File.open('baz', 'w') { |f| f.write 'quux' }
    assert_equal 'bar', File.open('foo') { |f| f.read }
  end

  def test_cp_r_should_raise_error_on_missing_file
    # Yes, this error sucks, but it conforms to the original Ruby
    # method.
    assert_raise(RuntimeError) do
      FileUtils.cp_r 'blafgag', 'foo'
    end
  end

  def test_cp_r_handles_copying_directories
    FileUtils.mkdir_p 'subdir'
    Dir.chdir('subdir'){ File.open('foo', 'w') { |f| f.write 'footext' } }

    FileUtils.mkdir_p 'baz'

    # To a previously uncreated directory
    FileUtils.cp_r('subdir', 'quux')
    assert_equal 'footext', File.open('quux/foo') { |f| f.read }

    # To a directory that already exists
    FileUtils.cp_r('subdir', 'baz')
    assert_equal 'footext', File.open('baz/subdir/foo') { |f| f.read }

    # To a subdirectory of a directory that does not exist
    assert_raises(Errno::ENOENT) do
      FileUtils.cp_r('subdir', 'nope/something')
    end
  end

  def test_cp_r_array_of_files
    FileUtils.mkdir_p 'subdir'
    File.open('foo', 'w') { |f| f.write 'footext' }
    File.open('bar', 'w') { |f| f.write 'bartext' }
    FileUtils.cp_r(%w(foo bar), 'subdir')

    assert_equal 'footext', File.open('subdir/foo') { |f| f.read }
    assert_equal 'bartext', File.open('subdir/bar') { |f| f.read }
  end

  def test_cp_r_array_of_directories
    %w(foo bar subdir).each { |d| FileUtils.mkdir_p d }
    File.open('foo/baz', 'w') { |f| f.write 'baztext' }
    File.open('bar/quux', 'w') { |f| f.write 'quuxtext' }

    FileUtils.cp_r(%w(foo bar), 'subdir')
    assert_equal 'baztext', File.open('subdir/foo/baz') { |f| f.read }
    assert_equal 'quuxtext', File.open('subdir/bar/quux') { |f| f.read }
  end

  def test_cp_r_only_copies_into_directories
    FileUtils.mkdir_p 'subdir'
    Dir.chdir('subdir') { File.open('foo', 'w') { |f| f.write 'footext' } }

    File.open('bar', 'w') { |f| f.write 'bartext' }

    assert_raises(Errno::EEXIST) do
      FileUtils.cp_r 'subdir', 'bar'
    end

    FileUtils.mkdir_p 'otherdir'
    FileUtils.ln_s 'otherdir', 'symdir'

    FileUtils.cp_r 'subdir', 'symdir'
    assert_equal 'footext', File.open('symdir/subdir/foo') { |f| f.read }
  end

  def test_cp_r_sets_parent_correctly
    FileUtils.mkdir_p '/path/foo'
    File.open('/path/foo/bar', 'w') { |f| f.write 'foo' }
    File.open('/path/foo/baz', 'w') { |f| f.write 'foo' }

    FileUtils.cp_r '/path/foo', '/path/bar'

    assert File.exists?('/path/bar/baz')
    FileUtils.rm_rf '/path/bar/baz'
    assert_equal %w( /path/bar/bar ), Dir['/path/bar/*']
  end

  def test_putting_a_dot_at_end_copies_the_contents
    FileUtils.mkdir_p 'subdir'
    Dir.chdir('subdir') { File.open('foo', 'w') { |f| f.write 'footext' } }

    FileUtils.mkdir_p 'newdir'
    FileUtils.cp_r 'subdir/.', 'newdir'
    assert_equal 'footext', File.open('newdir/foo') { |f| f.read }
  end

  def test_files_can_be_touched
    FileUtils.touch('touched_file')
    assert File.exists?('touched_file')
    list = ['newfile', 'another']
    FileUtils.touch(list)
    list.each { |fp| assert(File.exists?(fp)) }
  end

  def test_touch_does_not_work_if_the_dir_path_cannot_be_found
    assert_raises(Errno::ENOENT) do
      FileUtils.touch('this/path/should/not/be/here')
    end
    FileUtils.mkdir_p('subdir')
    list = ['subdir/foo', 'nosubdir/bar']

    assert_raises(Errno::ENOENT) do
      FileUtils.touch(list)
    end
  end

  def test_file_utils_compare_file
    file1 = 'file1.txt'
    file2 = 'file2.txt'
    file3 = 'file3.txt'
    content = "This is my \n file\content\n"
    File.open(file1, 'w') do |f|
      f.write content
    end
    File.open(file3, 'w') do |f|
      f.write "#{content} with additional content"
    end

    FileUtils.cp file1, file2

    assert_equal FileUtils.compare_file(file1, file2), true
    assert_equal FileUtils.compare_file(file1, file3), false
    assert_raises Errno::ENOENT do
      FileUtils.compare_file(file1, "file4.txt")
    end
  end
end
