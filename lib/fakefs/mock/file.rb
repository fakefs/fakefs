module FakeFS
  class MockFile
    attr_accessor :name, :parent, :content

    def initialize(name = nil, parent = nil)
      @name = name
      @parent = parent
      @content = ''
    end

    def clone(parent = nil)
      clone = super()
      clone.parent = parent if parent
      clone
    end

    def entry
      self
    end

    def inspect
      "(MockFile name:#{name.inspect} parent:#{parent.to_s.inspect} size:#{content.size})"
    end

    def to_s
      File.join(parent.to_s, name)
    end
  end
end