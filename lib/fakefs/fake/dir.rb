module FakeFS
  class FakeDir < Hash
    attr_accessor :name, :parent

    def initialize(name = nil, parent = nil)
      @name = name
      @parent = parent
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
      if parent && parent.to_s != '.'
        File.join(parent.to_s, name)
      elsif parent && parent.to_s == '.'
        "#{File::PATH_SEPARATOR}#{name}"
      else
        name
      end
    end

    def delete(node = self)
      if node == self
        parent.delete(self)
      else
        super(node.name)
      end
    end
  end
end
