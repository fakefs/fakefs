require "test_helper"

class RequireTest < Test::Unit::TestCase

  def setup
    @original_dir = Dir.pwd
    @dir = RealDir.tmpdir + "/" + rand.to_s[2..-1]
    Dir.mkdir @dir
    Dir.chdir @dir
    
    FakeFS.activate!
    
    $LOAD_PATH.unshift @dir
  end
  
  def teardown
    FakeFS::Require.deactivate!
    FakeFS::Require.clear
    
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
    
    File.open("foo.rb", "w") {|f|
      f.write "module FakeFS::Foo; end"
    }
    
    assert require "foo"
    assert FakeFS::Foo
    
    FakeFS.send :remove_const, :Foo
  end
  
  def test_fails_if_file_doesnt_exist
    FakeFS::Require.activate!
    
    assert_raise(LoadError) { require "foo" }
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
    skip "$LOADED_FEATURES behaviour is not up-to-date with tests' expectations"
    
    FakeFS::Require.activate!
    
    File.open("loaded_feature.rb", "w") {|f|
      f.write "module FakeFS::LoadedFeature; end"
    }
    require "loaded_feature"
    
    assert_equal @dir + "/loaded_feature.rb", $LOADED_FEATURES.last
    assert_false require("loaded_feature")
    
    FakeFS.send :remove_const, :LoadedFeature
  end
  
  def test_deactivates_itself_properly
    FakeFS::Require.activate!
    FakeFS::Require.deactivate!
    
    assert_raise(LoadError) { require "i_dont_exist" }
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
  
  def test_requires_autorequire_files
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
    
    File.open("with_load.rb", "w") {|f|
      f.write "module FakeFS::WithLoad; " +
                "@count ||= 0; @count += 1; def self.count; @count; end; " +
              "end"
    }
    
    1.upto(3) {|i|
      load "with_load.rb"
      assert_equal i, FakeFS::WithLoad.count
    }
  end
  
  def test_load_doesnt_append_dot_rb
    FakeFS::Require.activate! :load => true
    
    File.open("no_dot_rb.rb", "w") {|f|
      f.write ""
    }
    assert_raise(LoadError) { load "no_dot_rb "}
  end
  
  def test_load_executes_with_an_anonymous_module
    FakeFS::Require.activate! :load => true
    
    File.open("anonymous.rb", "w") {|f|
      f.write "module Anonymous; end"
    }

    load "anonymous.rb", true
    assert_raise(NameError) { Anonymous }
  end
  
  def test_load_uses_fallback
    skip "Not implemented yet."
    
    # load with fallback
    begin
      FakeFS::Require.opts[:fallback] = true
      
      dir = RealDir.tmpdir + "/" + rand.to_s[2..-1]
      RealDir.mkdir dir
      $LOAD_PATH.unshift dir
      
      code = <<-EOS
        module FakeFSTestLoadWithFallback
        end
      EOS
      RealFile.open dir + "/fake_fs_test_load_with_fallback.rb", "w" do |f|
        f.write code
      end
      
      load "fake_fs_test_load_with_fallback.rb"
      assert FakeFSTestLoadWithFallback
    ensure
      RealFile.delete dir + "/fake_fs_test_load_with_fallback.rb"
      RealDir.delete dir
      $LOAD_PATH.delete dir
    end
  end
  
  def test_load_fallback_fails_if_file_doesnt_exist_in_original_fs
    skip "Not implemented yet."
    
    # failing load without fallback
    begin
      FakeFS::Require.opts[:fallback] = false
      
      dir = RealDir.tmpdir + "/" + rand.to_s[2..-1]
      RealDir.mkdir dir
      $LOAD_PATH.unshift dir
      
      code = <<-EOS
        module FakeFSTestLoadWithoutFallback
        end
      EOS
      RealFile.open dir + "/fake_fs_test_load_without_fallback.rb", "w" do |f|
        f.write code
      end
      
      assert_raise(LoadError) { load "fake_fs_test_load_without_fallback.rb" }
    ensure
      RealFile.delete dir + "/fake_fs_test_load_without_fallback.rb"
      RealDir.delete dir
      $LOAD_PATH.delete dir
    end
  end
  
  def test_load_doesnt_load_files_in_original_fs_without_fallback
    skip "Not implemented yet."
  end
  
  def test_load_return_values
    skip "Not implemented yet."
  end
end
