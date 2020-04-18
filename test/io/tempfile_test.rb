require_relative '../test_helper'

# tempfile and io interaction test
class TempfileIOTest < Minitest::Test
  include FakeFS

  def setup
    FileSystem.clear
    FileUtils.mkdir_p(Dir.tmpdir)
  end

  def test_create_with_foreach_single_line
    Tempfile.create('') do |f|
      f.write('Hello World!')
      f.flush # normally f.close works but FakeFS deletes the file

      IO.foreach(f.path) do |line|
        assert_equal('Hello World!', line)
      end
    end
  end

  def test_create_with_foreach_multi_line
    Tempfile.create('') do |f|
      f.write("Hello World!\nfoo\nbar\n")
      f.flush # normally f.close works but FakeFS deletes the file

      lines = []

      IO.foreach(f.path) do |line|
        lines << line
      end

      assert_equal(["Hello World!\n", "foo\n", "bar\n"], lines)
    end
  end

  def test_create_with_expand_path_foreach_single_line
    Tempfile.create('') do |f|
      f.write('Hello World!')
      f.flush # normally f.close works but FakeFS deletes the file

      file = File.expand_path(f.path)

      IO.foreach(file) do |line|
        assert_equal('Hello World!', line)
      end
    end
  end
end
