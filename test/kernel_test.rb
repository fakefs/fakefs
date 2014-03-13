require 'test_helper'

class KernelTest < Test::Unit::TestCase
  include FakeFS
  def setup
    FakeFS.deactivate!
  end

  def teardown
    FakeFS.activate!
  end

  def test_can_exec_normally
    out = open("|echo 'foo'")
    assert_equal "foo\n", out.gets
  end

  def test_fake_kernel_can_create_subprocesses
    FakeFS do
      out = open("|echo 'foo'")
      assert_equal "foo\n", out.gets
    end
  end

  def test_fake_kernel_can_create_new_file
    FakeFS do
      FileUtils.mkdir_p '/path/to/'
      open('/path/to/file', "w") do |f|
        f << "test"
      end
      assert_kind_of FakeFile, FileSystem.fs['path']['to']['file']
    end
  end

  def test_fake_kernel_can_do_stuff
    FakeFS do
      FileUtils.mkdir_p('/tmp')
      File.open('/tmp/a', 'w+') { |f| f.puts 'test' }

      begin
      puts open('/tmp/a').read
      rescue Exception => e
        puts e
        puts e.backtrace
        raise e
      end
    end
  end

  def test_can_exec_normally2
    out = open("|echo 'foo'")
    assert_equal "foo\n", out.gets
  end

end

