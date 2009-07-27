module FakeFS
  class FakeSymlink
    attr_accessor :name, :target
    alias_method  :to_s, :name

    def initialize(target)
      @target = target
    end

    def inspect
      "symlink(#{target.split('/').last})"
    end

    def entry
      FileSystem.find(target)
    end

    def method_missing(*args, &block)
      entry.send(*args, &block)
    end
  end
end
