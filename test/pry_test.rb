require_relative 'test_helper'

require 'pry'

class PryTest < Minitest::Test
  include FakeFS

  def setup
    FakeFS.activate!
    FileSystem.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def test_show_source
    Pry.run_command("show-source FakeFS.activate!", show_output: false)
    assert_nil Pry.last_internal_error
  end
end
