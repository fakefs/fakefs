require "test_helper"

class RequireTest < Test::Unit::TestCase

  def setup
    FakeFS.activate!
    
    $LOAD_PATH << "."
  end

  def teardown
    FakeFS::Require.deactivate!
    FakeFS::Require.clear
    
    FakeFS::FileSystem.clear
    FakeFS.deactivate!
    
    $LOAD_PATH.delete "."
  end
  
  def test_fakes_require
    FakeFS::Require.activate!
    
    # require a file
    code = <<-EOS
      module FakeFSTestRequire1
      end
    EOS
    File.open "fake_fs_test_require1.rb", "w" do |f|
      f.write code
    end
    require "fake_fs_test_require1.rb"
    assert ::FakeFSTestRequire1
    
    # require a file that doesn't exist
    assert_raise LoadError do
      require "foo"
    end
    
    # always append .rb if the filename doesn't end with it
    code = <<-EOS
      module FakeFSTestRequire2_WithDotRb
      end
    EOS
    File.open "fake_fs_test_require2.rb", "w" do |f|
      f.write code
    end
    code = <<-EOS
      module FakeFSTestRequire2_WithoutDotRb
      end
    EOS
    File.open "fake_fs_test_require2", "w" do |f|
      f.write code
    end
    require "fake_fs_test_require2"
    assert ::FakeFSTestRequire2_WithDotRb
    
    # remember which files have been loaded
    code = <<-EOS
      module FakeFSTestRequire3
      end
    EOS
    File.open "fake_fs_test_require3.rb", "w" do |f|
      f.write code
    end
    require "fake_fs_test_require3"
    assert_equal "fake_fs_test_require3.rb", $".last
    assert !require("fake_fs_test_require3")
    
    # properly deactivate
    FakeFS::Require.deactivate!
    assert_raise LoadError do
      require "bar"
    end
  end
  
  def test_fakes_require_with_fallback
    FakeFS::Require.activate! :fallback => true
    
    # load a file that's in the real (= non-faked) load path
    begin
      dir = RealDir.tmpdir + "/" + rand.to_s[2..-1]
      RealDir.mkdir dir
      
      $LOAD_PATH.unshift dir
      
      code = <<-EOS
        module FakeFSTestRequireWithFallback
        end
      EOS
      RealFile.open dir + "/fake_fs_test_require_with_fallback.rb", "w" do |f|
        f.write code
      end
      
      require "fake_fs_test_require_with_fallback.rb"
      assert FakeFSTestRequireWithFallback
    ensure
      RealFile.delete dir + "/fake_fs_test_require_with_fallback.rb"
      RealDir.delete dir
      $LOAD_PATH.delete dir
    end
    
    # load a file that exists neither in fakefs nor in the real load path
    assert_raise LoadError do
      require "fake_fs_test_require_with_fooback.rb"
    end
    
    # turned off fallback
    begin
      dir = RealDir.tmpdir + "/" + rand.to_s[2..-1]
      RealDir.mkdir dir
      $LOAD_PATH.unshift dir
      RealFile.open dir + "/fake_fs_test_require_without_fallback.rb", "w" do |f|; end
      
      FakeFS::Require.opts[:fallback] = false
      assert_raise LoadError do
        require "fake_fs_test_require_without_fallbacK"
      end
    ensure
      RealFile.delete dir + "/fake_fs_test_require_without_fallback.rb"
      $LOAD_PATH.delete dir
      RealDir.delete dir
    end
  end
  
  def test_fakes_autoload
    FakeFS::Require.activate! :autoload => true
    
    code = <<-EOS
      module FakeFSTestAutoload
        autoload :Foo, "fake_fs_test_autoload/foo"
        autoload :Bar, "fake_fs_test_autoload/bar"
      end
    EOS
    File.open "fake_fs_test_autoload.rb", "w" do |f|
      f.write code
    end
    code = <<-EOS
      module FakeFSTestAutoload
        module Foo
        end
      end
    EOS
    File.open "fake_fs_test_autoload/foo.rb", "w" do |f|
      f.write code
    end
    
    require "fake_fs_test_autoload"
    
    # autoload
    assert FakeFSTestAutoload::Foo
    
    # autoload with non-existing path
    assert_raise LoadError do
      FakeFSTestAutoload::Bar
    end
    
    # no autoload
    assert_raise NameError do
      FakeFSTestAutoload::Baz
    end
  end
  
  # TODO test return values
  def test_fakes_load
    FakeFS::Require.activate! :load => true
    
    # loads a file
    File.open "fake_fs_test_load.rb", "w" do |f|
      f.write <<-CODE
        module FakeFSTestLoad
          @count ||= 0
          @count += 1
          def self.count; return @count; end
        end
      CODE
    end
    load "fake_fs_test_load.rb"
    assert_equal 1, FakeFSTestLoad.count
    
    # loads the file twice
    load "fake_fs_test_load.rb"
    assert_equal 2, FakeFSTestLoad.count
    
    # doesn't append .rb
    # TODO i don't get this line.
    assert_raise(LoadError) { load "fake_fs_test_load/asd.rb" }
    
    # executes the file within an anonymous module
    File.open "fake_fs_test_load3.rb", "w" do |f|
      f.write <<-CODE
        module FakeFSTestLoad3
        end
      CODE
    end
    load "fake_fs_test_load3.rb", true
    assert_raise(NameError) { FakeFSTestLoad3 }
    
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

end
