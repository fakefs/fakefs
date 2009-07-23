module FakeFS
  class Dir
    def self.glob(pattern)
      if pattern[-1,1] == '*'
        blk = proc { |entry| entry.to_s }
      else
        blk = proc { |entry| entry[1].parent.to_s }
      end
      (FileSystem.find(pattern) || []).map(&blk).uniq.sort
    end

    def self.[](pattern)
      glob(pattern)
    end

    def self.chdir(dir, &blk)
      FileSystem.chdir(dir, &blk)
    end
  end
end