require 'test_helper'
require 'tempfile'

# Tempfile test class
class TempfileTest < Minitest::Test
  include FakeFS

  if RUBY_VERSION >= '2.1'
    def test_should_not_raise_error
      FakeFS do
        # nothing raised
        FileUtils.mkdir_p('/tmp')
        Tempfile.open('test')
      end
    end
  else
    def test_noop
      # TODO: Remove me when we add non-2.1 tests.
    end
  end
end
