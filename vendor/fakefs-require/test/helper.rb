require "rubygems"
require "bundler"
Bundler.setup(:default, :development)

require "fakefs/safe"
require "fakefs/require"

require "test/unit"
require "mocha"

require "tmpdir"

require "awesome_print"
