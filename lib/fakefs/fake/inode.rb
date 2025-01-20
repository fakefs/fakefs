# frozen_string_literal: true

module FakeFS
  # Inode class
  class FakeInode
    @freed_inodes = []
    @next_inode_num = 0

    def initialize(file_owner)
      @content = ''.encode(Encoding.default_external)
      @links = [file_owner]
      assign_inode_num
    end

    attr_accessor :content, :links, :inode_num

    # please see: http://iacobson.net/beware-of-ruby-class-variables/
    class << self
      attr_accessor :freed_inodes, :next_inode_num

      # This method should only be used for tests
      # When called, it will reset the current inode information of the FakeFS
      def clear_inode_info_for_tests
        self.freed_inodes = []
        self.next_inode_num = 0
      end
    end

    def assign_inode_num
      unless (@inode_num = self.class.freed_inodes.shift)
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
end
