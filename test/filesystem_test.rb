# -*- coding: utf-8 -*-
require "test_helper"

class FileSystemTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_can_be_initialized_empty
    fs = FileSystem
    assert_equal 0, fs.files.size
  end

  def test_can_be_initialized_with_an_existing_directory
    fs = FileSystem
    fs.clone(File.expand_path(File.dirname(__FILE__))).inspect
    assert_equal 1, fs.files.size
  end
end
