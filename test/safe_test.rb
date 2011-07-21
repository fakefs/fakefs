require "test_helper"

class FakeFSSafeTest < Test::Unit::TestCase
  def setup
    FakeFS.deactivate!
  end

  def teardown
    FakeFS.activate!
  end

  def test_FakeFS_method_does_not_intrude_on_global_namespace
    path = 'file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write "Yatta!" }
      assert File.exists?(path)
    end

    assert ! File.exists?(path)
  end

  def test_FakeFS_method_returns_value_of_yield
    result = FakeFS do
      File.open('myfile.txt', 'w') { |f| f.write "Yatta!" }
      File.read('myfile.txt')
    end

    assert_equal result, "Yatta!"
  end

  def test_FakeFS_method_deactivates_FakeFS_when_block_raises_exception
    begin
      FakeFS do
        raise 'boom!'
      end
    rescue
    end

    assert_equal RealFile, File, "File is #{File} (should be #{RealFile})"
    assert_equal RealFileUtils, FileUtils, "FileUtils is #{FileUtils} (should be #{RealFileUtils})"
    assert_equal RealDir, Dir, "Dir is #{Dir} (should be #{RealDir})"
  end
end
