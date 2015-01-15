require 'test_helper'

# File join test class
class FileJoin < Minitest::Test
  def setup
    FakeFS.activate!
  end

  def teardown
    FakeFS.deactivate!
  end

  [
    %w(a b),  %w(a/ b), %w(a /b), %w(a/ /b), %w(a / b)
  ].each_with_index do |args, i|
    define_method "test_file_join_#{i}" do
      assert_equal RealFile.join(args), File.join(args)
    end
  end
end
