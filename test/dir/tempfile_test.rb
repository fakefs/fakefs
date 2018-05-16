require_relative '../test_helper'
require 'tempfile'

# Tempfile test class
class TempfileTest < Minitest::Test
  include FakeFS

  def test_should_not_raise_error
    FakeFS do
      # nothing raised
      FileUtils.mkdir_p('/tmp')
      Tempfile.open('test')
    end
  end
end
