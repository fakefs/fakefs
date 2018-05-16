require_relative 'test_helper'

# FakeFS safe test class
class SafeTest < Minitest::Test
  def setup
    FakeFS.deactivate!
  end

  def teardown
    FakeFS.activate!
  end

  def test_FakeFS_activated_is_accurate
    2.times do
      FakeFS.deactivate!
      refute FakeFS.activated?
      FakeFS.activate!
      assert FakeFS.activated?
    end
  end

  def test_FakeFS_method_does_not_intrude_on_global_namespace
    path = 'file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write 'Yatta!' }
      assert File.exist?(path)
    end

    refute File.exist?(path)
  end

  def test_FakeFS_method_presents_persistent_fs
    path = 'file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write 'Yatta!' }
      assert File.exist?(path)
    end

    refute File.exist?(path)

    FakeFS do
      assert File.exist?(path)
    end
  end

  def test_FakeFS_fresh_method_presents_fresh_fs
    path = 'file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write 'Yatta!' }
      assert File.exist?(path)
    end

    refute File.exist?(path)

    FakeFS.with_fresh do
      refute File.exist?(path)
    end
  end

  def test_FakeFS_clear_method_clears_fs
    path = 'file.txt'

    FakeFS do
      File.open(path, 'w') { |f| f.write 'Yatta!' }
      assert File.exist?(path)
    end

    refute File.exist?(path)

    FakeFS.clear!

    FakeFS do
      refute File.exist?(path)
    end
  end

  def test_FakeFS_method_returns_value_of_yield
    result = FakeFS do
      File.open('myfile.txt', 'w') { |f| f.write 'Yatta!' }
      File.read('myfile.txt')
    end

    assert_equal result, 'Yatta!'
  end

  def test_FakeFS_method_does_not_deactivate_FakeFS_if_already_activated
    FakeFS.activate!
    FakeFS {}

    assert FakeFS.activated?
  end

  def test_FakeFS_method_can_be_nested
    FakeFS do
      assert FakeFS.activated?
      FakeFS do
        assert FakeFS.activated?
      end
      assert FakeFS.activated?
    end

    refute FakeFS.activated?
  end

  def test_FakeFS_method_can_be_nested_with_FakeFS_without
    FakeFS do
      assert FakeFS.activated?
      FakeFS.without do
        refute FakeFS.activated?
      end
      assert FakeFS.activated?
    end

    refute FakeFS.activated?
  end

  def test_FakeFS_method_deactivates_FakeFS_when_block_raises_exception
    begin
      FakeFS do
        raise 'boom!'
      end
    rescue StandardError
      'Nothing to do'
    end

    refute FakeFS.activated?
  end
end
