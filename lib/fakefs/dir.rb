module FakeFS
  class Dir
    def self.glob(pattern)
      [FileSystem.find(pattern) || []].flatten.map{|e| e.to_s}.sort
    end

    def self.[](pattern)
      glob(pattern)
    end

    def self.chdir(dir, &blk)
      FileSystem.chdir(dir, &blk)
    end

    def self.pwd
      FileSystem.current_dir.to_s
    end

    class << self
      alias_method :getwd, :pwd
    end
  end
end
