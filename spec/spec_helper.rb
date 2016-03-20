$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end