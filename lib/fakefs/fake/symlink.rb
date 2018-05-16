module FakeFS
  # Fake symlink class
  class FakeSymlink
    attr_accessor :name, :target, :parent

    def initialize(target)
      @target = target
    end

    def inspect
      "symlink(#{name} -> #{target.split('/').last})"
    end

    def entry
      FileSystem.find(File.expand_path(target.to_s, parent.to_s))
    end

    def delete
      parent.delete(self)
    end

    def to_s
      File.join(parent.to_s, name)
    end

    def respond_to_missing?(method, include_private = false)
      entry.respond_to?(method, include_private)
    end

    private

    def method_missing(*args, &block) # rubocop:disable Style/MethodMissingSuper
      entry.send(*args, &block)
    end
  end
end
