require 'test_helper'

class KernelTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_fake_kernel_can_create_subprocesses
    out = open("| echo 'foo'")
    assert_match /^foo/, out.gets
  end

  def test_fake_kernel_can_create_new_file
    file = open('some_file', "w") do |f|
      f << "test"
    end
    assert_kind_of FakeFS::File, file
  end

  def test_fake_kernel_can_be_activated
    FakeFS::File.open "some_file", "w" do |f|
      f.write "test"
    end
    assert_nothing_raised do
      open('some_file')
    end
  end

  def test_fake_kernel_can_be_deactivated
    FakeFS::File.open "some_other_file", "w" do |f|
      f.write "test"
    end
    act_on_real_fs do
      assert_raise Errno::ENOENT do
        open('some_other_file')
      end
    end
  end
end
