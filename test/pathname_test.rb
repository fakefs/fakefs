require 'test_helper'

# Fake Pathname test class
class FakePathnameTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear

    @path = 'foo'
    @pathname = Pathname.new(@path)
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_filetest_exists_returns_correct_value
    assert !@pathname.exist?

    File.write(@path, '')

    assert @pathname.exist?
  end

  def test_io_each_line_with_block_yields_lines
    File.write(@path, "one\ntwo\nthree\n")

    yielded = []
    @pathname.each_line { |line| yielded << line }

    assert_equal yielded, ["one\n", "two\n", "three\n"]
  end

  def test_io_each_line_without_block_returns_enumerator
    File.write(@path, '')

    assert @pathname.each_line.is_a?(Enumerator)
  end

  def test_io_read_returns_file_contents
    File.write(@path, "some\ncontent")

    assert_equal @pathname.read, "some\ncontent"
    assert_equal @pathname.read(6), "some\nc"
    assert_equal @pathname.read(4, 3), "e\nco"
  end

  def test_io_binread_returns_file_contents
    File.write(@path, "some\ncontent")

    assert_equal @pathname.binread, "some\ncontent"
    assert_equal @pathname.binread(6), "some\nc"
    assert_equal @pathname.binread(4, 3), "e\nco"
  end

  def test_io_binread_reads_contents_as_binary
    File.write(@path, "some\ncontent")

    assert_equal @pathname.binread.encoding.name, 'ASCII-8BIT'
  end

  def test_io_readlines_returns_array_of_lines
    File.write(@path, "one\ntwo\nthree\n")

    assert_equal @pathname.readlines, ["one\n", "two\n", "three\n"]
  end

  def test_io_sysopen_is_unsupported
    assert_raise(NotImplementedError) { @pathname.sysopen }
  end
end
