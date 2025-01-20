# frozen_string_literal: true

module FakeFS
  # FakeFS IO class inherit root IO
  # Only minimal mocks are provided as IO may be used by ruby's internals
  class IO < ::IO
    # Redirects ::IO.binread to ::FakeFS::File.binread
    def self.binread(*args)
      ::FakeFS::File.binread(*args)
    end

    # Redirects ::IO.read to ::FakeFS::File.read
    def self.read(*args)
      ::FakeFS::File.read(*args)
    end

    # Redirects ::IO.write to ::FakeFS::File.write
    def self.write(*args)
      ::FakeFS::File.write(*args)
    end
  end
end
