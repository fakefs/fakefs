module FakeFS
  class FakeDir < Hash
    attr_accessor :name, :parent
    attr_reader :ctime, :mtime

    def initialize(name = nil, parent = nil)
      @name   = name
      @parent = parent
      @ctime  = Time.now
      @mtime  = @ctime
    end

    def entry
      self
    end

    def inspect
      "(FakeDir name:#{name.inspect} parent:#{parent.to_s.inspect} size:#{size})"
    end

    def clone(parent = nil)
      clone = Marshal.load(Marshal.dump(self))
      clone.each do |key, value|
        value.parent = clone
      end
      clone.parent = parent if parent
      clone
    end


      

    def to_s
      if parent
        result = File.join(parent.to_s, name).gsub("//", "/")
      else
        result = name
      end
      result = "/" if result == "."
      result
    end

    def delete(node = self)
      if node == self
        parent.delete(self)
      else
        super(node.name)
      end
    end

    def inspect_tree
      inspect_tree_helper(0)
    end

    def inspect_tree_helper(indent = 0)
      in_s = " " * indent
      result = in_s + "#{name}/"
      self.values.each do |value|
        case value 
        when FakeDir
          result += "\n#{in_s}  " + value.inspect_tree_helper(indent + 2)
        when FakeFile
          result += "\n#{in_s}  " + value.name
        when FakeSymlink
          result += "\n#{in_s}  " + value.name + " -> " + value.target
        end
      end
      result
    end
        
      

  end
end
