# frozen_string_literal: true

require_relative '../test_helper'

# File stat test class
class FileFlockTest < Minitest::Test
  include FakeFS

  class ValidMode
    def to_int
      File::LOCK_EX
    end
  end

  class InvalidMode
    def to_int
      10_000_000
    end
  end

  class InvalidToIntMode
    def to_int
      File::LOCK_EX.to_s
    end
  end

  def setup
    FileSystem.clear
  end

  def test_invalid_flock
    File.open('file', 'w') do |f|
      assert_raises(Errno::EINVAL) do
        f.flock(1_000_000_000)
      end
      assert_raises(Errno::EINVAL) do
        f.flock(InvalidMode.new)
      end
      assert_raises(TypeError) do
        f.flock(InvalidToIntMode.new)
      end
      assert_raises(TypeError) do
        f.flock('1000000000')
      end
      assert_raises(TypeError) do
        f.flock(File::LOCK_EX.to_s)
      end
    end
  end

  def test_valid_flock
    File.open('file', 'w') do |f|
      assert f.flock(File::LOCK_EX) == 0
      assert f.flock(File::LOCK_SH) == 0
      assert f.flock(File::LOCK_UN) == 0
      assert f.flock(File::LOCK_EX | File::LOCK_NB) == 0
      assert f.flock(File::LOCK_SH | File::LOCK_NB) == 0
      assert f.flock(File::LOCK_UN | File::LOCK_NB) == 0
      assert f.flock(ValidMode.new) == 0
    end
  end
end
