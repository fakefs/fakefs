RealFile            = File
RealFileTest        = FileTest
RealFileUtils       = FileUtils
RealDir             = Dir
RealPathname        = Pathname

def RealPathname(*args)
  RealPathname.new(*args)
end

def Pathname(*args)
  Pathname.new(*args)
end

# FakeFS module
module FakeFS
  class << self
    def activated?
      @activated ? true : false
    end

    # unconditionally activate
    def activate!
      Object.class_eval do
        remove_const(:Dir)
        remove_const(:File)
        remove_const(:FileTest)
        remove_const(:FileUtils)
        remove_const(:Pathname)

        const_set(:Dir,       FakeFS::Dir)
        const_set(:File,      FakeFS::File)
        const_set(:FileUtils, FakeFS::FileUtils)
        const_set(:FileTest,  FakeFS::FileTest)
        const_set(:Pathname,  FakeFS::Pathname)
        ::FakeFS::Kernel.hijack!
      end

      @activated = true

      true
    end

    # unconditionally deactivate
    def deactivate!
      Object.class_eval do
        remove_const(:Dir)
        remove_const(:File)
        remove_const(:FileTest)
        remove_const(:FileUtils)
        remove_const(:Pathname)

        const_set(:Dir,       RealDir)
        const_set(:File,      RealFile)
        const_set(:FileTest,  RealFileTest)
        const_set(:FileUtils, RealFileUtils)
        const_set(:Pathname,  RealPathname)
        ::FakeFS::Kernel.unhijack!
      end

      @activated = false

      true
    end

    # unconditionally clear the fake filesystem
    def clear!
      ::FakeFS::FileSystem.clear
    end

    # present a fresh new fake filesystem to the block
    def with_fresh(&block)
      clear!
      with(&block)
    end

    # present the fake filesystem to the block
    def with
      if activated?
        yield
      else
        begin
          activate!
          yield
        ensure
          deactivate!
        end
      end
    end

    # present a non-fake filesystem to the block
    def without
      if !activated?
        yield
      else
        begin
          deactivate!
          yield
        ensure
          activate!
        end
      end
    end
  end
end

def FakeFS(&block)
  return ::FakeFS unless block
  ::FakeFS.with(&block)
end
