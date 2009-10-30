# FakeFS::SpecHelpers provides a simple macro for RSpec example groups to turn FakeFS on and off.
# To use it simply require 'fakefs/spec_helpers', then include FakeFS::SpecHelpers into any
# example groups that you wish to use FakeFS in. For example:
#
#   require 'fakefs/spec_helpers'
#
#   describe "Some specs that deal with files" do
#     include FakeFS::SpecHelpers
#     ...
#   end
#
# Alternatively, you can include FakeFS::SpecHelpers in all your example groups using RSpec's
# configuration block in your spec helper:
#
#   require 'fakefs/spec_helpers'
#
#   Spec::Runner.configure do |config|
#     config.include FakeFS::SpecHelpers
#   end
#
# If you do the above then use_fakefs will be available in all of your example groups.
#
require 'fakefs/safe'

module FakeFS
  module SpecHelpers
    def self.extended(example_group)
      example_group.use_fakefs(example_group)
    end

    def self.included(example_group)
      example_group.extend self
    end

    def use_fakefs(describe_block)
      describe_block.before :each do
        FakeFS.activate!
      end

      describe_block.after :each do
        FakeFS.deactivate!
        FakeFS::FileSystem.clear
      end
    end
  end
end
