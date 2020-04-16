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
end
