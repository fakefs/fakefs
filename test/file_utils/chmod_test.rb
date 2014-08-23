# -*- coding: utf-8 -*-
require "test_helper"

class ChmodTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
    FileUtils.touch(good)
  end

  def teardown
    FakeFS.deactivate!
  end

  def good
    'file.txt'
  end

  def bad
    'nofile.txt'
  end

  def test_can_chmod_files
    assert_equal [good], FileUtils.chmod(0600, good, :verbose => true)
    assert_equal File.stat(good).mode, 0100600
    assert_equal File.executable?(good), false
  end

  def test_cannot_chmod_nonexistant_file
    assert_raises(Errno::ENOENT) do
      FileUtils.chmod(0600, bad)
    end
    assert_raises(Errno::ENOENT) do
      FileUtils.chmod(0666, bad)
    end
  end

  def test_giving_everyone_permissions
    assert_equal [good], FileUtils.chmod(0666, good)
    assert_equal File.stat(good).mode, 0100666
  end

  def test_chmodding_multiple_existant_files
    FileUtils.touch('good2')
    assert_equal [good, 'good2'], FileUtils.chmod(0644, [good, 'good2'])
    assert_equal File.stat(good).mode, 0100644
    assert_equal File.stat('good2').mode, 0100644
  end

  def test_cannot_chmod_multiple_files_if_some_dont_exist
    assert_raises(Errno::ENOENT) do
      FileUtils.chmod(0644, [good, bad])
    end
  end

  def test_setting_file_to_executable
    assert_equal [good], FileUtils.chmod(0744, [good])
    assert_equal File.executable?(good), true
  end

  def test_setting_file_to_nonexecutable
    # This behaviour is unimplemented, the spec below is only to show that it
    # is a deliberate YAGNI omission.
    assert_equal [good], FileUtils.chmod(0477, [good])
    assert_equal File.executable?(good), false
  end

  def test_can_chmod_R_files
    FileUtils.mkdir_p "/path/sub"
    FileUtils.touch "/path/file1"
    FileUtils.touch "/path/sub/file2"

    assert_equal ["/path"], FileUtils.chmod_R(0600, "/path")
    assert_equal File.stat("/path").mode, 0100600
    assert_equal File.stat("/path/file1").mode, 0100600
    assert_equal File.stat("/path/sub").mode, 0100600
    assert_equal File.stat("/path/sub/file2").mode, 0100600

    FileUtils.mkdir_p "/path2"
    FileUtils.touch "/path2/hej"
    assert_equal ["/path2"], FileUtils.chmod_R(0600, "/path2")
  end
end
