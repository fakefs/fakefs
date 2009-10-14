# FakeFS::SpecHelpers provides a simple macro for RSpec example groups to turn FakeFS on and off.
# To use it simply require 'fakefs/safe' and 'fakefs/spec_helpers'.  Then include FakeFS::SpecHelpers into any
# example groups that you wish to use FakeFS in.  The "use_fakefs" macro is then available to install
# before and after hooks which will enable and disable FakeFS.  For example:
#
#   require 'fakefs/safe'
#   require 'fakefs/spec_helpers'
#   describe SomeClassThatDealsWithFiles
#     include FakeFS::SpecHelpers
#     use_fakefs
#     ...
#   end
#
# Alternatively, you can include FakeFS::SpecHelpers in all your example groups using RSpec's
# configuration block in your spec helper:
#
#   require 'fakefs/safe'
#   require 'fakefs/spec_helpers'
#   Spec::Runner.configure do |config|
#     config.extend FakeFS::SpecHelpers
#   end
#
# If you do the above then use_fakefs will be available in all of your example groups.
#
module FakeFS
  module SpecHelpers
    def use_fakefs
      before(:each) do
        FakeFS.activate!
      end

      after(:each) do
        FakeFS.deactivate!
        FakeFS::FileSystem.clear
      end
    end
  end
end
