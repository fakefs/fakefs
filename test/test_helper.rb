$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'fakefs/safe'
require 'test/unit'

begin
  require 'redgreen'
rescue LoadError
end