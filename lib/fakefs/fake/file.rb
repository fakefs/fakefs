module FakeFS
  # Fake file class
  class FakeFile
    attr_accessor :name, :parent, :mtime, :atime, :mode, :uid, :gid
    attr_reader :ctime, :birthtime

    # Inode class
    class Inode
      @freed_inodes = []
      @next_inode_num = 0

      def initialize(file_owner)
        @content = ''.encode(Encoding.default_external)
        @links = [file_owner]
        assign_inode_num
      end

      attr_accessor :content
      attr_accessor :links
      attr_accessor :inode_num

      # please see: http://iacobson.net/beware-of-ruby-class-variables/
      class << self
        attr_accessor :freed_inodes
        attr_accessor :next_inode_num

        # This method should only be used for tests
        # When called, it will reset the current inode information of the FakeFS
        def clear_inode_info_for_tests
          self.freed_inodes = []
          self.next_inode_num = 0
        end
      end

      def assign_inode_num
        if (@inode_num = self.class.freed_inodes.shift)
        else
          @inode_num = self.class.next_inode_num
          self.class.next_inode_num += 1
        end
      end

      def free_inode_num
        self.class.freed_inodes.push(@inode_num)
      end

      def link(file)
        links << file unless links.include?(file)
        file.inode = self
      end

      def unlink(file)
        links.delete(file)
      end

      def clone
        clone = super
        clone.content = content.dup
        clone.assign_inode_num
        clone
      end
    end

    def initialize(name = nil, parent = nil)
      @name      = name
      @parent    = parent
      @inode     = Inode.new(self)
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
