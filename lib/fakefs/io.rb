module FakeFS
  # FakeFS IO class inherit root IO
  # Only minimal mocks are provided as IO may be used by ruby's internals
  class IO < ::IO
    # Redirects ::IO.read to ::FakeFS::File.read
    def self.read(*args, **keywords)
      ::FakeFS::File.read(*args, **keywords)
    end

    # Redirects ::IO.write to ::FakeFS::File.write
    def self.write(*args, **keywords)
      ::FakeFS::File.write(*args, **keywords)
    end
  end
end
