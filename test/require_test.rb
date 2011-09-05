require "test_helper"

class RequireTest < Test::Unit::TestCase

  def setup
    @original_dir = Dir.pwd
    @dir = "/tmp/" + rand.to_s[2..-1]

    Dir.mkdir @dir
    Dir.chdir @dir


    FakeFS.activate!
    FakeFS::FileSystem.clone(@dir)
    Dir.chdir @dir

    $LOAD_PATH.unshift @dir
  end
  
  def teardown
    FakeFS::Require.deactivate!
    #FakeFS::Require.clear
    
    FakeFS::FileSystem.clear
    FakeFS.deactivate!
  ensure
    $LOAD_PATH.delete @dir
    $LOADED_FEATURES.delete_if {|path|
      path =~ /^#{Regexp.escape @dir}\//
    }
    
    Dir.chdir @original_dir
    FileUtils.rm_r @dir
  end
  
  def test_requires_file
    FakeFS::Require.activate!
    
    FileUtils.mkdir "foo"
    $LOAD_PATH << "foo"
    FileUtils.mkdir "bar"
    $LOAD_PATH << "bar"
    
    File.open("foo/cool_load_path.rb", "w") {|f|
      f.write "module FakeFS::Foo; end"
    }
    File.open("bar/cool_load_path.rb", "w") {|f|
      f.write ""
    }
    
    assert require "cool_load_path"
    assert FakeFS::Foo
    
    FakeFS.send :remove_const, :Foo
  ensure
    $LOAD_PATH.delete "foo"
    $LOAD_PATH.delete "bar"
  end
  
  def test_fails_if_file_doesnt_exist
    FakeFS::Require.activate!
    
    assert_raise(LoadError) { require "foo" }
  end
  
  def test_requires_file_from_absolute_path
    FakeFS::Require.activate!
    
    path = @dir + "/an/absolute/path"
    FileUtils.mkdir_p @dir + "/an/absolute"
    File.open(path + ".rb", "w") {|f|
      f.write "module FakeFS::AnAbsolutePath; end"
    }
    assert require path
    assert FakeFS::AnAbsolutePath
    
    FakeFS.send :remove_const, :AnAbsolutePath
  end
  
  def test_uses_absolute_path_for_caller
    FakeFS::Require.activate!
    
    File.open("error.rb", "w") {|f|
      f.write "this will raise a name error"
    }
    
    begin
      require "error"
      fail "nothing raised"
    rescue NameError => e
      assert_match /^#{@dir + "/error.rb"}:1:in /, e.backtrace[0]
    end
  end
  
  def test_appends_dot_rb_to_filename
    FakeFS::Require.activate!
    
    File.open("dot_rb.rb", "w") {|f|
      f.write "module FakeFS::DotRb; end"
    }
    File.open("dot_rb", "w") {|f|
      f.write "module FakeFS::NoDotRb; end"
    }
    
    require "dot_rb"
    assert FakeFS::DotRb
    
    FakeFS.send :remove_const, :DotRb
  end
  
  def test_doesnt_append_dot_rb_if_present
    FakeFS::Require.activate!
    
    File.open("2nd_dot_rb.rb", "w") {|f|
      f.write "module FakeFS::No2ndDotRb; end"
    }
    File.open("2nd_dot_rb.rb.rb", "w") {|f|
      f.write "module FakeFS::2ndDotRb; end"
    }
    
    require "2nd_dot_rb.rb"
    assert FakeFS::No2ndDotRb
    
    FakeFS.send :remove_const, :No2ndDotRb
  end
  
  def test_remembers_required_files
    FakeFS::Require.activate!
    
    FileUtils.mkdir "foo"
    $LOAD_PATH << "foo"
    
    File.open("load_it.rb", "w") {|f|
      f.write "require 'loaded_feature'"
    }
    File.open("foo/loaded_feature.rb", "w") {|f|
      f.write "module FakeFS::LoadedFeature; end"
    }
    require "load_it"
    
    assert_equal @dir + "/foo/loaded_feature.rb", $LOADED_FEATURES[-2]
    assert_equal @dir + "/load_it.rb", $LOADED_FEATURES[-1]
    
    assert !require("loaded_feature")
    
    FakeFS.send :remove_const, :LoadedFeature
  ensure
    $LOAD_PATH.delete "foo"
  end
  
  def test_deactivates_itself_properly
    FakeFS::Require.activate! :load => true, :fallback => true
    File.open("i_dont_exist.rb", "w") {|f|
      f.write ""
    }
    
    FakeFS::Require.deactivate!
    assert_raise(LoadError) { require "i_dont_exist" }
    assert_raise(LoadError) { load "i_dont_exist.rb" }
  end
  
  def test_falls_back_to_original_fs
    FakeFS::Require.activate! :fallback => true
    
    RealFile.open("with_fallback.rb", "w") {|f|
      f.write "module FakeFS::WithFallback; end"
    }
    require "with_fallback"
    assert  FakeFS::WithFallback
    
    FakeFS.send :remove_const, :WithFallback
  end
  
  def test_doesnt_require_files_in_original_fs_without_fallback
    FakeFS::Require.activate!
    
    RealFile.open("without_fallback.rb", "w") {|f|
      f.write ""
    }
    assert_raise(LoadError) { require "without_fallback" }
  end
  
  def test_fails_if_file_doesnt_exist_in_both_faked_and_original_fs
    FakeFS::Require.activate! :fallback => true
    
    assert_raise(LoadError) { require "i_dont_exist" }
  end
  
  def test_requires_autoload_files
    FakeFS::Require.activate! :autoload => true
    
    File.open("with_autoload.rb", "w") {|f|
      f.write "module FakeFS::WithAutoload; end"
    }
    FakeFS.send :autoload, :WithAutoload, "with_autoload"
    
    assert FakeFS::WithAutoload
    FakeFS.send :remove_const, :WithAutoload
  end
  
  def test_fails_if_autoload_file_doesnt_exist
    FakeFS::Require.activate! :autoload => true
    
    FakeFS.send :autoload, :WithAutoload, "i_dont_exist"
    assert_raise(LoadError) { FakeFS::WithAutoload }
  end
  
  def test_fails_if_autoloaded_file_doesnt_define_constant
    FakeFS::Require.activate! :autoload => true
    
    File.open("empty.rb", "w") {|f|
      f.write ""
    }
    FakeFS.send :autoload, :EmptyAutoload, "empty"
    
    assert_raise(NameError) { FakeFS::EmptyAutoload }
  end
  
  def test_fakes_load
    FakeFS::Require.activate! :load => true
    
    FileUtils.mkdir "foo"
    $LOAD_PATH << "foo"
    FileUtils.mkdir "bar"
    $LOAD_PATH << "bar"
    
    File.open("foo/zomg_load_path.rb", "w") {|f|
      f.write "module FakeFS::Foo; " +
                "@count ||= 0; @count += 1; def self.count; @count; end; " +
              "end"
    }
    File.open("bar/zomg_load_path.rb", "w") {|f|
      f.write ""
    }
    
    1.upto(3) {|i|
      assert load "zomg_load_path.rb"
      assert_equal i, FakeFS::Foo.count
    }
  end
  
  def test_load_fails_if_file_doesnt_exist
    FakeFS::Require.activate! :load => true
    
    assert_raise(LoadError) { load "i_dont_exist" }
  end
  
  def test_load_file_from_absolute_path
    FakeFS::Require.activate! :load => true
    
    path = @dir + "/an/absolute/path.rb"
    FileUtils.mkdir_p @dir + "/an/absolute/"
    File.open(path, "w") {|f|
      f.write "module FakeFS::AnAbsolutePath; end"
    }
    load path
    assert FakeFS::AnAbsolutePath
    
    FakeFS.send :remove_const, :AnAbsolutePath
  end
  
  def test_load_uses_absolute_path_for_caller
    FakeFS::Require.activate! :load => true
    
    File.open("error.rb", "w") {|f|
      f.write "this will raise a name error"
    }
    
    begin
      load "error.rb"
      fail "nothing raised"
    rescue NameError => e
      assert_match /^#{@dir + "/error.rb"}:1:in /, e.backtrace[0]
    end
  end
  
  def test_load_doesnt_append_dot_rb
    FakeFS::Require.activate! :load => true
    
    File.open("no_dot_rb.rb", "w") {|f|
      f.write ""
    }
    assert_raise(LoadError) { load "no_dot_rb"}
  end
  
  def test_load_executes_within_an_anonymous_module
    FakeFS::Require.activate! :load => true
    
    File.open("anonymous.rb", "w") {|f|
      f.write "module Anonymous; end"
    }

    load "anonymous.rb", true
    assert_raise(NameError) { ::Anonymous }
  end
  
  def test_load_uses_fallback
    FakeFS::Require.activate! :fallback => true, :load => true
    
    RealFile.open("with_fallback.rb", "w") {|f|
      f.write "module FakeFS::WithFallback; end"
    }
    
    load "with_fallback.rb"
    assert FakeFS::WithFallback
    
    FakeFS.send :remove_const, :WithFallback
  end
  
  def test_load_fallback_fails_if_file_doesnt_exist_in_original_fs
    FakeFS::Require.activate! :fallback => true, :load => true
    
    assert_raise(LoadError) { load "i_dont_exist.rb" }
  end
  
  def test_load_doesnt_load_files_in_original_fs_without_fallback
    FakeFS::Require.activate! :load => true
    
    RealFile.open("without_fallback.rb", "w") {|f|
      f.write ""
    }
    
    assert_raise(LoadError) { load "without_fallback.rb" }
  end
end
