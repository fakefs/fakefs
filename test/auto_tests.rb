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
      pathname.rmtree
    end
    Dir.mkdir(test_path)
    real_test = AutoTestObject.new(:real, test_path)
    fake_test = AutoTestObject.new(:fake, test_path)

    # firstly execute the code in the fake file system
    # this is done in a thread so that SAFE can be set
    # without it leaking into the rest of the program
    FakeFS::FileSystem.clone(test_path)
    thread = Thread.new do
      # TODO: this should be enabled or be an option
      # $SAFE = 3
      FakeFS do
        fake_test.instance_exec(test_path, &block)
      end
    end
    thread.join

    # clear the filesystem ready for the real run 
    FakeFS::FileSystem.clear
    pathname.rmdir
    Dir.mkdir(test_path)

    real_test.instance_exec(test_path, &block)

    compare_fileystem_checks(real_test.filesystem_checks,
                             fake_test.filesystem_checks)
    
    if real_test.value_checks != fake_test.value_checks
      
    end
      
  end

  # creates an assertion failure with the given message, as if it
  # was created at the given location.
  # Example: 
  #   raise_assertion-failure("values not equal", "auto_test.rb:18")
  def raise_assertion_failure(message, location)
    begin
      flunk message
    rescue Exception => e
      p e.class
      # new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)
      e.set_backtrace(location)
      raise e
    end
  end

  def compare_fileystem_checks(expected_fschecks, actual_fschecks)
    missing_checks = expected_fschecks.keys - actual_fschecks.keys
    unless (missing_checks.empty?)
      missing_checks.each do |check|
        msg = "the check at the given location wasn't performed in the fake filesystem"
        check_count = check.check_count(missing_checks)
        msg += " (#{check_count} at this location)" if check_count > 1
        raise_assertion_failure(msg, check.location)
      end
    end
    extra_checks = expected_fschecks.keys - actual_fschecks.keys
    unless (extra_checks.empty?)
      missing_checks.each do |check|
        msg = <<-EOF
        the check at the given location was performed in the fake filesystem,
        but not the real file system
        EOF
        check_count = check.check_count(missing_checks)
        msg += " (#{check_count} at this location)" if check_count > 1
        raise_assertion_failure(msg, check.location)
      end
    end
      
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
    # todo fix assertions to throw error at right spot
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
      @filesystem_check_count = 0
      @value_check_count = 0
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

      check_info = CheckInfo.new(@filesystem_check_count, caller()[0])
      @filesystem_check_count += 1
      @filesystem_checks[check_info] = new_value
    end

    def check_value(value)
      check_info = CheckInfo.new(@value_check_count, caller()[0])
      @value_check_count += 1

      @value_checks[check_info] = value
    end

  end

  class CheckInfo
    include Comparable
    def <=>(other)
      number <=> other.number
    end

    def hash()
      number.hash
    end
    
    def eql?(other)
      self == other
    end

    def initialize(number, location)
      @number, @location = number, location
    end

    # counts the number of times a check at the same location
    # as this check appears in the other_check_array
    def check_count(other_check_array)
      other_check_array.select {|c| c.location == location}.length
    end
      
    attr_accessor :location, :number
  end
    

end

class AutoTests < Test::Unit::TestCase
  include FakeFsTester

  def test_should_fail
    compare_with_real do |path|
      check_filesystem
      Dir.mkdir(path + "somedir1" + rand().to_s)
      Dir.mkdir(path + "somedir")
      Dir.mkdir(path + "somedir/lol")
      check_filesystem
      check_value "this"
      # check_value Dir.entries(path)
    end
  end

end

# $a = AutoTests.new
