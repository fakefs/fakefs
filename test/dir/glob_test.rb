# -*- coding: utf-8 -*-
require "test_helper"

class DirGlobTest < Test::Unit::TestCase
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_dir_glob_finds_exact_match_directories
    setup_directories

    assert_equal ['/path'], Dir['/path']
    assert_equal ['/path/foo'], Dir['/path/foo']
  end

  def test_dir_glob_matches_wildcard_in_directory
    setup_directories

    assert_equal %w( /path/bar /path/bar2 /path/foo /path/foobar ), Dir['/path/*']
    assert_equal ['/path/bar/baz'], Dir['/path/bar/*']
  end

  def test_dir_glob_matches_wildcard_in_filename
    setup_directories

    assert_equal ['/path'], Dir['/path*']
    assert_equal ['/path/foo', '/path/foobar'], Dir['/p*h/foo*']
  end

  def test_dir_glob_matches_single_wildcard_in_filename
    setup_directories

    assert_equal ['/path/foo', '/path/foobar'], Dir['/p??h/foo*']
  end

  def test_dir_glob_matches_double_wildcard_for_nested_directories
    setup_directories

    assert_equal ['/path/bar', '/path/bar/baz', '/path/bar2', '/path/bar2/baz', '/path/foo', '/path/foobar'], Dir['/path/**/*']
    assert_equal ['/path', '/path/bar', '/path/bar/baz', '/path/bar2', '/path/bar2/baz', '/path/foo', '/path/foobar'], Dir['/**/*']

    assert_equal ['/path/bar', '/path/bar/baz', '/path/bar2', '/path/bar2/baz', '/path/foo', '/path/foobar'], Dir['/path/**/*']
    assert_equal ['/path/bar/baz'], Dir['/path/bar/**/*']

    assert_equal ['/path/bar/baz', '/path/bar2/baz'], Dir['/path/bar/**/*', '/path/bar2/**/*']
    assert_equal ['/path/bar/baz', '/path/bar2/baz', '/path/bar/baz'], Dir['/path/ba*/**/*', '/path/bar/**/*']
  end

  def test_glob_handles_wildcard_root
    setup_directories
    FileUtils.cp_r '/path', '/otherpath'

    assert_equal %w(/otherpath/foo /otherpath/foobar /path/foo /path/foobar), Dir['/*/foo*']
  end

  def test_glob_handles_bracketed_options
    setup_directories

    assert_equal ['/path/bar', '/path/foo'], Dir['/path/{foo,bar}']
    assert_equal ['/path/bar', '/path/bar2'], Dir['/path/bar{2,}']
  end

  def test_glob_works_after_chdir
    setup_directories

    Dir.chdir '/path' do
      assert_equal ['foo'], Dir['foo']
    end
  end

  private

  def setup_directories
    FileUtils.mkdir_p '/path'
    touch_files ['/path/foo', '/path/foobar']

    FileUtils.mkdir_p '/path/bar'
    touch_file '/path/bar/baz'

    FileUtils.cp_r '/path/bar', '/path/bar2'
  end
end
