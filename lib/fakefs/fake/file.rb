module FakeFS
  class FakeFile
    attr_accessor :name, :parent

    class Inode
      def initialize(file_owner)
        @content = ""
        @links   = [file_owner]
      end

      attr_accessor :content
      attr_accessor :links

      def link(file)
        links << file unless links.include?(file)
        file.inode = self
      end
    end

    def initialize(name = nil, parent = nil)
      @name   = name
      @parent = parent
      @inode  = Inode.new(self)
    end

    attr_accessor :inode

    def content
      @inode.content
    end

    def content=(str)
      @inode.content = str
    end

    def links
      @inode.links
    end

    def link(other_file)
      @inode.link(other_file)
    end

    def clone(parent = nil)
      clone = super()
      clone.parent = parent if parent
      clone.inode  = inode.clone
      clone
    end

    def entry
      self
    end

    def inspect
      "(FakeFile name:#{name.inspect} parent:#{parent.to_s.inspect} size:#{content.size})"
    end

    def to_s
      File.join(parent.to_s, name)
    end
  end
end
