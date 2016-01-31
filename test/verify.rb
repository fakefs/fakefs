# Figure out what's missing from fakefs
#
# USAGE
#
#   $ ruby test/verify.rb | grep "not implemented"

require_relative 'test_helper'

# FakeFs verifier test class
class FakeFSVerifierTest < Minitest::Test
  class_mapping = {
    RealFile       => FakeFS::File,
    RealFile::Stat => FakeFS::File::Stat,
    RealFileUtils  => FakeFS::FileUtils,
    RealDir        => FakeFS::Dir,
    RealFileTest   => FakeFS::FileTest
  }

  class_mapping.each do |real_class, fake_class|
    real_class.methods.each do |method|
      define_method "test_#{method}_class_method" do
        assert fake_class.respond_to?(method),
               "#{fake_class}.#{method} not implemented"
      end
    end

    real_class.instance_methods.each do |method|
      define_method("test_#{method}_instance_method") do
        assert fake_class.instance_methods.include?(method),
               "#{fake_class}##{method} not implemented"
      end
    end
  end
end
