require 'test_helper'

# Fake Pathname test class
class FakePathnameTest < Minitest::Test
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
    refute @pathname.exist?

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
    File.write(@path, "one\ntwo\nthree\n")

    assert @pathname.each_line.is_a?(Enumerator)
    assert_equal %w(o t t), @pathname.each_line.map { |l| l[0] }
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

  def test_io_readlines_returns_array_of_lines
    File.write(@path, "one\ntwo\nthree\n")

    assert_equal ["one\n", "two\n", "three\n"], @pathname.readlines
  end

  def test_io_sysopen_is_unsupported
    assert_raises(NotImplementedError) { @pathname.sysopen }
  end
end
