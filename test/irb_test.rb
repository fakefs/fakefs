# frozen_string_literal: true

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
    FakeFS::FileSystem.clear
  end

  def test_setup_irb
    assert_includes [nil, true], IRB.setup(binding.source_location[0], argv: [])
  end
end
