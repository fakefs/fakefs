# Figure out what's missing from fakefs
#
# USAGE
#
#   $ ruby test/verify.rb | grep "not implemented"
require 'fakefs'
require 'test/unit'
 
class FakeFSVerifierTest < Test::Unit::TestCase
  (RealFile.methods - Class.new.methods).each do |name|
    define_method("test #{name} class method") do
      assert File.respond_to?(name), "File.#{name} not implemented"
    end
  end
 
  (RealFile.instance_methods - Enumerable.instance_methods).each do |name|
    define_method("test #{name} instance method") do
      assert File.instance_methods.include?(name), "File##{name} not implemented"
    end
  end
 
  (RealFileUtils.methods - Class.new.methods).each do |name|
    define_method("test #{name} module method") do
      assert FileUtils.respond_to?(name), "FileUtils.#{name} not implemented"
    end
  end
end
