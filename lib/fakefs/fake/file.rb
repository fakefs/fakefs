module FakeFS
  # Fake file class
  class FakeFile
    attr_accessor :name, :parent, :mtime, :atime, :mode, :uid, :gid
    attr_reader :ctime, :birthtime

    def initialize(name = nil, parent = nil)
      @name      = name
      @parent    = parent
      @inode     = FakeInode.new(self)
      @ctime     = Time.now
      @mtime     = @ctime
      @atime     = @ctime
      @birthtime = @ctime
      @mode      = 0o100000 + (0o666 - File.umask)
      @uid       = Process.uid
      @gid       = Process.gid
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
      "(FakeFile name:#{name.inspect} " \
      "parent:#{parent.to_s.inspect} size:#{content.size})"
    end

    def to_s
      File.join(parent.to_s, name)
    end

    def delete
      inode.unlink(self)
      inode.free_inode_num
      parent.delete(self)
    end
  end
end
