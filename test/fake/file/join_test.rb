require_relative '../../test_helper'

# File join test class
class FakeFileJoinTest < Minitest::Test
  def setup
    FakeFS.activate!
  end

  def teardown
    FakeFS.deactivate!
  end

  [
    ['a', 'b'], ['a/', 'b'], ['a', '/b'], ['a/', '/b'], ['a', '/', 'b']
  ].each_with_index do |args, i|
    define_method "test_file_join_#{i}" do
      assert_equal RealFile.join(args), File.join(args)
    end
  end
end
