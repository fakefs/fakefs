require_relative 'test_helper'

require 'irb'

class IrbTest < Minitest::Test
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_setup_irb
    assert_nil IRB.setup(binding.source_location[0], argv: [])
  end
end
