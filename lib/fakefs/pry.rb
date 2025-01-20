# frozen_string_literal: true

# Define Pry class if it's not defined. Useful if pry
# is required after loading FakeFS
::Pry = Class.new unless defined?(::Pry)

# Make the original file system classes available in Pry.
::Pry::File = ::File
::Pry::FileUtils = ::FileUtils
::Pry::Dir = ::Dir
::Pry::Pathname = ::Pathname
