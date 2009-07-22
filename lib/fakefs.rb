require 'fileutils'
require 'pathname'
require 'fakefs/safe'

Object.class_eval do
  remove_const(:Dir)
  remove_const(:File)
  remove_const(:FileUtils)
end

File = FakeFS::File
FileUtils = FakeFS::FileUtils
Dir = FakeFS::Dir
