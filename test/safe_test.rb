require_relative 'test_helper'

# FakeFS safe test class
class SafeTest < Minitest::Test
  def teardown
    FakeFS.deactivate!
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

  def test_FakeFS_method_stubs_File_class_but_not_IO
    old_file = ::File
    old_io = ::IO

    FakeFS do
      refute_equal old_file, ::File
      assert_equal old_io, ::IO
    end
  end

  def test_FakeFS_method_stubs_IO_class_if_explicity_asked
    old_file = ::File
    old_io = ::IO

    FakeFS(io_mocks: true) do
      refute_equal old_file, ::File
      refute_equal old_io, ::IO
    end
  end

  def test_FakeFS_method_restore_original_File_and_IO_classes_on_return
    old_file = ::File
    old_io = ::IO

    FakeFS(io_mocks: true) {}

    assert_equal old_file, ::File
    assert_equal old_io, ::IO
  end

  def test_FakeFS_method_fails_if_FakeFS_already_activated_with_io_mocks
    FakeFS.activate!(io_mocks: true)
    assert_raises(FakeFS::ActivationError) { FakeFS {} }
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

  def test_FakeFS_method_can_be_nested_with_io_mocks
    FakeFS(io_mocks: true) do
      assert FakeFS.activated?
      FakeFS(io_mocks: true) do
        assert FakeFS.activated?
      end
      assert FakeFS.activated?
    end

    refute FakeFS.activated?
  end

  def test_FakeFS_method_can_not_be_nested_with_different_io_mocks_param
    assert_raises(FakeFS::ActivationError) do
      FakeFS(io_mocks: false) do
        assert FakeFS.activated?
        FakeFS(io_mocks: true) {}
      end
    end
    refute FakeFS.activated?

    assert_raises(FakeFS::ActivationError) do
      FakeFS(io_mocks: true) do
        assert FakeFS.activated?
        FakeFS(io_mocks: false) {}
      end
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
    FakeFS(io_mocks: true) do
      assert FakeFS.activated?
      FakeFS.without do
        refute FakeFS.activated?
      end
      assert FakeFS.activated?
      assert FakeFS.activated?(io_mocks: true)
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

  def test_FakeFS_activate_method_stubs_File_class_but_not_IO
    old_file = ::File
    old_io = ::IO

    ::FakeFS.activate!

    refute_equal old_file, ::File
    assert_equal old_io, ::IO
  ensure
    ::FakeFS.deactivate!
  end

  def test_FakeFS_activate_method_stubs_IO_class_if_explicity_asked
    old_file = ::File
    old_io = ::IO

    ::FakeFS.activate!(io_mocks: true)

    refute_equal old_file, ::File
    refute_equal old_io, ::IO
  ensure
    ::FakeFS.deactivate!
  end

  def test_FakeFS_deactivate_restore_original_File_and_IO_classes
    old_file = ::File
    old_io = ::IO

    ::FakeFS.activate!(io_mocks: true)
    ::FakeFS.deactivate!

    assert_equal old_file, ::File
    assert_equal old_io, ::IO
  ensure
    ::FakeFS.deactivate!
  end
end
