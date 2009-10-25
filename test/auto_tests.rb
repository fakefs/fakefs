$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
# require 'fakefs'
require 'test/unit'
require 'fakefs/safe'
require 'pathname'

  

module FakeFsTester
  # runs the code in the given block, firstly in the real file system,
  # then in the Fake file system. The method will then compare the results,
  # and cause assert errors for any differences.
  #
  # The block may also use a check_value method. This takes a value, and checks if that
  # value is the same in both FakeFS and the real file system
  #
  # The block takes one parameter, a String giving the path to a temporary directory
  # For example "/tmp/autotest-asdf/"
  # This should be used as the base of all tests. The directory will be deleted after
  # the tests has been finished in the real file system.
  #
  # Additional Options:
  # time_measurement_tolerence:<num>   
  # If the mod/access/change times of an item in the file systems differ by less than 
  # this amount (in seconds), then the change won't be reported as an error. This is useful for longer
  # running tests, since the clock may change in the time it takes to run the test.
  # Defaults to 1.
  # test_time: <bool>:
  # Whether to test mod/access/change times at all. Defaults to true.
  #
  # Example Usage:
  # compare_with_real(time_measurement_tolerance: 2) do |path|
  #   Dir.mkdir(path + "somedir")
  #   check_filesystem
  #   check_value Dir.entries
  # end
  #
  # Note that this test depends on clone working correctly
  # 
  def compare_with_real(options = {}, &block)
    test_path = "/tmp/autotest-dir/"
    pathname = Pathname.new(test_path)
    
    if pathname.exist? 
      p "REMOVING STUFF"
      pathname.rmtree
    end
    Dir.mkdir(test_path)
    real_test = AutoTestObject.new(:real, test_path)
    fake_test = AutoTestObject.new(:fake, test_path)


    FakeFS::FileSystem.clone(test_path)

    thread = Thread.new do
      # TODO: this should be enabled or be an option
      # $SAFE = 3
      FakeFS do
        fake_test.instance_exec(test_path, &block)
        Dir.mkdir(test_path + "/lol")
      end
      p "here"
    end
    
    thread.join
    FakeFS::FileSystem.clear
      
    pathname.rmdir
    Dir.mkdir(test_path)

    real_test.instance_exec(test_path, &block)

    p "real_test: #{real_test.inspect}"
    p "fake_test: #{fake_test.inspect}"
    

    compare_fileystem_checks(real_test.filesystem_checks,
                             fake_test.filesystem_checks)
                             
      

    
    if real_test.value_checks != fake_test.value_checks
      flunk "this is bad value"
    end
      
  end

  def compare_fileystem_checks(expected_fschecks, actual_fschecks)
    assert_equal(expected_fschecks.size, actual_fschecks.size)
    assert_equal(expected_fschecks.keys, actual_fschecks.keys)

    expected_fschecks.keys.each do |key|
      compare_filesystems(expected_fschecks[key], actual_fschecks[key],
                          key)
    end
  end

  def compare_filesystems(expected_fs, actual_fs, location_info)
    # puts expected_fs.inspect_tree
    # puts actual_fs.inspect_tree
    # todo fix assertions to through error at right spot
    assert_equal(expected_fs.name, actual_fs.name)
    assert_equal(expected_fs.size, actual_fs.size)

    assert_equal(expected_fs.keys.sort, actual_fs.keys.sort)
    
    expected_fs.keys.each do |name|
      compare_filesystems(expected_fs[name], actual_fs[name], location_info)
    end
  end

    

  class AutoTestObject
    # creates a new AutoTestObject
    # @param mode the mode to run the test for (either :real or :fake)
    # @param base_path the path where the tests is taking place
    def initialize(mode, base_path)
      @mode = mode
      @base_path = base_path
      @filesystem_checks = {}
      @value_checks = {}
    end
    attr_accessor :filesystem_checks, :value_checks
    def check_filesystem
      if @mode == :fake
        new_value = FakeFS::FileSystem.fs.clone
      else
        FakeFS::FileSystem.clone(@base_path)
        new_value = FakeFS::FileSystem.fs
        FakeFS::FileSystem.clear
      end

      @filesystem_checks[caller()[0]] = new_value
    end

    def check_value(value)
      @value_checks[caller()[0]] = value
    end

  end
    

end

class AutoTests < Test::Unit::TestCase
  include FakeFsTester

  def initialize()
  end
  
  def f
    compare_with_real do |path|
      check_filesystem
      Dir.mkdir(path + "somedir1") # + rand().to_s)
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "somedir/lol")
      check_filesystem
      check_value "this"
      # check_value Dir.entries(path)
    end
  end

end

$a = AutoTests.new
