# -*- coding: utf-8 -*-
require "test_helper"

class ChownTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
    FileUtils.touch good
    FileUtils.chown(original_user_id, original_group_id, good)
  end

  def original_user_id
    1337
  end

  def original_group_id
    1338
  end

  def teardown
    FakeFS.deactivate!
  end

  def username
    Etc.getpwuid(Process.uid).name
  end

  def groupname
    Etc.getgrgid(Process.gid).name
  end

  def good
    'file.txt'
  end

  def bad
    'nofile.txt'
  end

  def test_can_chown_existing_files_with_uid_and_gid
    out = FileUtils.chown(30, 31, good)
    assert_equal [good], out
    assert_equal File.stat(good).uid, 30
    assert_equal File.stat(good).gid, 31
  end

  def test_cannot_chown_nonexistant_files_with_uid_and_gid
    assert_raises(Errno::ENOENT) do
      FileUtils.chown(username, groupname, bad, :verbose => true)
    end
  end

  def test_can_chown_existing_files_with_username_and_groupname
    assert_equal [good], FileUtils.chown(username, groupname, good)
    assert_ids_match_process good
  end

  def test_cannot_chown_nonexistant_files_with_username_and_groupname
    assert_raises(Errno::ENOENT) do
      FileUtils.chown(username, groupname, bad)
    end
  end

  def test_can_chown_multiple_existing_files
    files = %w(good1 good2)
    files.each {|f| FileUtils.touch f }

    assert_equal files, FileUtils.chown(username, groupname, files)
    files.each {|f| assert_ids_match_process f }
  end

  def test_cannot_chown_multiple_files_if_some_dont_exist
    assert_raises(Errno::ENOENT) do
      FileUtils.chown(username, groupname, [good, bad])
    end
  end

  def test_chown_with_nil_user_and_nil_group_does_not_change_anything
    FileUtils.chown(username, groupname, good)
    assert_ids_match_process good

    assert_equal [good], FileUtils.chown(nil, nil, [good])
    assert_ids_match_process good
  end

  def test_chown_with_nil_user_and_nil_group_errors_on_nonexistant_file
    assert_raises(Errno::ENOENT) do
      FileUtils.chown(nil, nil, [good, bad])
    end
  end

  def test_can_chown_R_files
    FileUtils.mkdir_p '/path/'
    FileUtils.touch('/path/foo')
    FileUtils.touch('/path/foobar')

    assert_equal ['/path'], FileUtils.chown_R(username, groupname, '/path')
    %w(/path /path/foo /path/foobar).each do |file|
      assert_ids_match_process file
    end
  end

  def assert_ids_match_process file
    assert_equal File.stat(file).uid, Process.uid
    assert_equal File.stat(file).gid, Process.gid
  end
end
