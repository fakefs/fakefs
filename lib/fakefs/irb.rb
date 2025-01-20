# frozen_string_literal: true

require 'irb'

# Make the original file system classes available in IRB.
::IRB::File = ::File
::IRB::FileUtils = ::FileUtils
::IRB::Dir = ::Dir
::IRB::Pathname = ::Pathname

# We need to setup IRB early, because the setup process itself requires locale files.
# Otherwise we'll get an error from Budler
#   Bundler::GemspecError: The gemspec for GEM_NAME was missing or broken.
#     Try running `gem pristine GEM_NAME -v GEM_VERSION` to fix the cached spec.
# because file sytem in bundler is stubbed.
IRB.setup(binding.source_location[0], argv: [])
