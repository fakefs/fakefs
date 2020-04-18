require_relative '../test_helper'
require 'tempfile'

# Tempfile test class
class TempfileTest < Minitest::Test
  include FakeFS

  def test_open_should_not_raise_error
    FakeFS do
      # nothing raised
      FileUtils.mkdir_p(Dir.tmpdir)
      Tempfile.open('test')
    end
  end

  def test_create_block
    FakeFS do
      # Ruby 2.3 requires a basename
      Tempfile.create('') do |f|
        assert_equal FakeFS::File, f.class

        f.write 'Hello World!'
        f.flush

        assert_equal 'Hello World!', File.read(f.path)
      end
    end
  end
end
