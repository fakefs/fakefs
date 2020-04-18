module FakeFS
  # IO
  class IO < RealIO
    def self.foreach(path, &block)
      File.readlines(path).each(&block)
    end
  end
end
