require 'test_helper'

# Globber test class
class GlobberTest < Minitest::Test
  def test_expand_without_brace_groups_returns_single_entry
    assert_equal ['*.rb'], FakeFS::Globber.expand('*.rb')
  end

  def test_expand_with_brace_group_with_one_entry_returns_single_entry
    assert_equal ['abc'], FakeFS::Globber.expand('{abc}')
  end

  def test_expand_with_brace_group_with_multiple_entries_returns_all_entries
    assert_equal %w(a b c), FakeFS::Globber.expand('{a,b,c}')
  end

  def test_expand_with_brace_group_with_nested_entries_expands_only_first_level
    assert_equal ['a', 'b', '{c,d}'], FakeFS::Globber.expand('{a,b,{c,d}}')
  end

  def test_path_components_with_no_globbing_splits_on_path_separator
    assert_equal %w(a b c), FakeFS::Globber.path_components('/a/b/c')
  end

  def test_path_components_with_path_separator_inside_brace_group
    assert_equal ['a', '{b,c/d}', 'e'], FakeFS::Globber.path_components('/a/{b,c/d}/e')
  end
end
