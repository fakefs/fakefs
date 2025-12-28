# frozen_string_literal: true

require_relative 'test_helper'

# Fake Pathname test class
class PathnameTest < Minitest::Test
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear

    @path = '/foo'
    @pathname = Pathname.new(@path)
  end

  def teardown
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  def test_filetest_exists_returns_correct_value
    refute @pathname.exist?

    File.write(@path, '')

    assert @pathname.exist?
  end

  def test_root_check_returns_correct_value
    refute @pathname.root?
    root_path = Pathname.new('/')
    assert root_path.root?
  end

  def test_io_each_line_with_block_yields_lines
    File.write(@path, "one\ntwo\nthree\n")

    yielded = []
    @pathname.each_line { |line| yielded << line }

    assert_equal yielded, ["one\n", "two\n", "three\n"]
  end

  def test_io_each_line_without_block_returns_enumerator
    File.write(@path, "one\ntwo\nthree\n")

    assert @pathname.each_line.is_a?(Enumerator)
    assert_equal(['o', 't', 't'], @pathname.each_line.map { |l| l[0] })
    assert_equal ["one\ntwo\nth", "ree\n"], @pathname.each_line('th').to_a
  end

  def test_io_read_returns_file_contents
    File.write(@path, "some\ncontent")

    assert_equal "some\ncontent", @pathname.read
    assert_equal "some\nc", @pathname.read(6)
    assert_equal "e\nco", @pathname.read(4, 3)
  end

  def test_io_binread_returns_file_contents
    File.write(@path, "some\ncontent")

    assert_equal "some\ncontent", @pathname.binread
    assert_equal "some\nc", @pathname.binread(6)
    assert_equal "e\nco", @pathname.binread(4, 3)
  end

  def test_io_binread_reads_contents_as_binary
    File.write(@path, "some\ncontent")

    assert_equal 'ASCII-8BIT', @pathname.binread.encoding.name
  end

  def test_io_binwrite
    bytes_written = @pathname.binwrite("some\ncontent")

    assert_equal 12, bytes_written
    assert_equal "some\ncontent", @pathname.binread
    assert_equal 'ASCII-8BIT', @pathname.binread.encoding.name
  end

  def test_io_readlines_returns_array_of_lines
    File.write(@path, "one\ntwo\nthree\n")

    assert_equal ["one\n", "two\n", "three\n"], @pathname.readlines
  end

  def test_io_sysopen_is_unsupported
    assert_raises(NotImplementedError) { @pathname.sysopen }
  end

  def test_files_are_unlinked
    File.write(@path, '')

    @pathname.unlink
    refute @pathname.exist?
  end

  def test_directories_are_unlinked
    Dir.mkdir(@path)

    @pathname.unlink
    refute @pathname.exist?
  end

  def test_file_is_written
    @pathname.write("some\ncontent")

    assert_equal "some\ncontent", @pathname.read
  end

  def test_pathname_slash
    assert_equal Pathname.new('foo') / 'bar', Pathname.new('foo/bar')
  end

  def test_pathname_size?
    @pathname.write("some\ncontent")
    assert_equal 12, @pathname.size?
  end

  def test_pathname_size
    @pathname.write("some\ncontent")
    assert_equal 12, @pathname.size
  end

  def test_pathname_glob
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('.zero'))
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    assert_equal [Pathname.new('/foo/one'), Pathname.new('/foo/two')], @pathname.glob('*')
  end

  def test_pathname_glob_takes_flags
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('.zero'))
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    assert_equal [Pathname.new('/foo/.zero'), Pathname.new('/foo/one'), Pathname.new('/foo/two')], @pathname.glob('*', File::FNM_DOTMATCH)
  end

  def test_pathname_glob_block
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    result = []
    @pathname.glob('*') { |pathname| result << pathname }
    assert_equal [Pathname.new('/foo/one'), Pathname.new('/foo/two')], result
  end

  def test_pathname_glob_class_method
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('.zero'))
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    assert_equal [Pathname.new('/foo/one'), Pathname.new('/foo/two')], Pathname.glob(@pathname.join('*'))
  end

  def test_pathname_glob_class_method_block
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    result = []
    Pathname.glob(@pathname.join('*')) { |pathname| result << pathname }
    assert_equal [Pathname.new('/foo/one'), Pathname.new('/foo/two')], result
  end

  def test_pathname_glob_class_method_flags
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('.zero'))
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    assert_equal [Pathname.new('/foo/.zero'), Pathname.new('/foo/one'), Pathname.new('/foo/two')], Pathname.glob(@pathname.join('*'), File::FNM_DOTMATCH)
  end

  def test_pathname_glob_class_method_flags_as_keyword
    FileUtils.mkdir(@pathname)
    FileUtils.touch(@pathname.join('.zero'))
    FileUtils.touch(@pathname.join('one'))
    FileUtils.touch(@pathname.join('two'))
    assert_equal [Pathname.new('/foo/.zero'), Pathname.new('/foo/one'), Pathname.new('/foo/two')], Pathname.glob(@pathname.join('*'), flags: File::FNM_DOTMATCH)
  end

  def test_pathname_glob_class_method_takes_base
    FileUtils.mkdir_p @pathname.join('bar')
    FileUtils.touch @pathname.join('bar', 'one')
    FileUtils.touch @pathname.join('bar', 'two')
    Dir.chdir(@pathname) do
      assert_equal [Pathname.new('one'), Pathname.new('two')], Pathname.glob('*', base: 'bar')
    end
  end

  def test_pathname_empty_on_empty_directory
    Dir.mkdir(@path)

    assert_equal true, @pathname.empty?
  end

  def test_pathname_empty_on_non_empty_directory
    Dir.mkdir(@path)
    file_path = File.join(@path, 'a_file.txt')
    FileUtils.touch(file_path)

    assert_equal false, @pathname.empty?
  end

  def test_pathname_empty_on_empty_file
    File.write(@path, '')

    assert_equal true, @pathname.empty?
  end

  def test_pathname_empty_on_non_empty_file
    File.write(@path, "some\ncontent")

    assert_equal false, @pathname.empty?
  end

  def test_pathname_empty_on_nonexistent_path
    refute @pathname.exist?

    assert_equal false, @pathname.empty?
  end

  def test_path
    assert_raises(NoMethodError, "is protected") { @pathname.path }
    assert_equal @pathname.send(:path), @path
  end

  def test_implements_all_methods
    FakeFS.deactivate!
    real = ::Pathname.instance_methods(false)
    FakeFS.activate!
    fake = Pathname.instance_methods(false)
    todo = [:birthtime, :lutime]
    deprecated = [:untaint, :taint]
    missing = real - fake - todo - deprecated
    assert_equal [], missing
  end
end
