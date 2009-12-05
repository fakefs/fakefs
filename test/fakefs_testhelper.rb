$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'test/unit'
require 'fakefs/safe'
require 'pathname'

  

module FakeFsTestHelper
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
  #
  # ignore_time: <bool>:
  # Whether to ignore mod/access/change times for testing. Defaults to false.
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
    comparer = CompareWithRealRunner.new(test_path, options)
    comparer.tester = self
    comparer.run_compare(&block)
  end

  # whether tests run with compare_with_real should be run
  # with $SAFE=3 for the fakefs test. This can detect whether 
  # the fakefs code is accidently touching the real file system (since
  # this will trigger a SecurityError with $SAFE = 3)
  # Defaults to false, as this doesn't work at all yet
  $run_tests_with_safe3 = false

  class CompareWithRealRunner

    attr_accessor :tester

    def initialize(test_path, options = {})
      @test_path = test_path
      @time_measurement_tolerance = options[:time_measurement_tolerance] || 1
      @ignore_time = options[:ignore_time]
    end

    def run_compare(&block)
      pathname = Pathname.new(@test_path)
      
      if pathname.exist? 
        pathname.rmtree
      end
      Dir.mkdir(@test_path)
      real_test = AutoTestObject.new(:real, @test_path)
      fake_test = AutoTestObject.new(:fake, @test_path)

      # firstly execute the code in the fake file system
      # this is done in a thread so that SAFE can be set
      # without it leaking into the rest of the program
      FakeFS::FileSystem.clone(@test_path)
      thread = Thread.new do
        # TODO: this should be enabled or be an option
        $SAFE = 3 if $run_tests_with_safe3
        FakeFS do
          fake_test.instance_exec(@test_path, &block)
        end
      end
      thread.join

      # clear the filesystem ready for the real run 
      FakeFS::FileSystem.clear
      pathname.rmdir
      Dir.mkdir(@test_path)

      real_test.instance_exec(@test_path, &block)

      compare_fileystem_checks(real_test.filesystem_checks,
                               fake_test.filesystem_checks)

      compare_value_checks(real_test.value_checks,
                           fake_test.value_checks)
    end

    # creates an assertion failure with the given message, as if it
    # was created at the given location.
    # Example: 
    #   raise_assertion-failure("values not equal", "auto_test.rb:18")
    def raise_assertion_failure(message, location)
      begin
        tester.flunk message
      rescue Exception => e
        # new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)
        e.set_backtrace([location])
        raise e
      end
    end

    def assert_equal_at(location, expected, actual, msg="")
      begin
        tester.assert_equal(expected, actual, msg)
      rescue Exception => e
        # new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)
        e.set_backtrace([location])
        raise e
      end
    end
    
    def compare_value_checks(expected_values, actual_values)
      expected_values.keys.each do |check_loc|
        unless actual_values.has_key? check_loc
          msg = "The value check at #{check_loc} wasn't performed"
          raise_assertion_failure(msg, check_loc)
        end
        assert_equal_at(check_loc,
                        expected_values[check_loc],
                        actual_values[check_loc])
      end
    end
    

    def compare_fileystem_checks(expected_fschecks, actual_fschecks)
      expected_fschecks.keys.each do |check_loc|
        unless actual_fschecks.has_key? check_loc
          msg = "The filesystem check at #{check_loc} wasn't performed"
          raise_assertion_failure(msg, check_loc)
        end
        compare_filesystems("/", check_loc,
                            expected_fschecks[check_loc],
                            actual_fschecks[check_loc])
      end
    end

    def compare_filesystems(curr_dir, location, expected_fs, actual_fs)
      assert_equal_at(location, expected_fs.name, actual_fs.name)
      assert_equal_at(location, expected_fs.size, actual_fs.size)

      assert_equal_at(location, expected_fs.keys.sort, actual_fs.keys.sort,
                      "directory entries for #{curr_dir} not equal")
      
      expected_fs.keys.each do |name|
        new_path = "#{curr_dir}#{name}"
        expected_entry = expected_fs[name]
        actual_entry = actual_fs[name]
        assert_equal_at(location, expected_entry.class, actual_entry.class,
                        "Filesystem object #{new_path} wrong type")
        case expected_entry
        when FakeFS::FakeDir
          compare_filesystems("#{new_path}/", location, expected_entry, actual_entry)
        when FakeFS::FakeFile
          compare_file(new_path, location, expected_entry, actual_entry)
        when FakeFS::FakeSymlink
          compare_symlink(new_path, location, expected_entry, actual_entry)
        end
      end
    end

    def compare_file(path, location, expected_file, actual_file)
      assert_equal_at(location, expected_file.content, actual_file.content,
                      "The content of the file #{path} is different")
      unless @ignore_time
        if (expected_file.mtime - actual_file.mtime).abs >= @time_measurement_tolerance 
          assert_equal_at(location, expected_file.mtime, actual_file.mtime,
                          "The mtime of the file #{path} is different")
        end
      end
      assert_equal_at(location, expected_file.links.map(&:name),
                      actual_file.links.map(&:name),
                      "The links of the file #{path} is different")
    end

    def compare_symlink(path, location, expected_symlink, actual_symlink)
      assert_equal_at(location, expected_symlink.target, actual_symlink.target)
      
    end
  end

    

  # this is the class of the object that the block passes to compare_with_real
  # is evaulated in, and supplies the check_filesystem and check_value methods.
  # It adds every check result to the hashes filesystem_checks and value_checks
  # using the location of the check as the key
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

