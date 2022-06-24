RealFile            = File
RealFileTest        = FileTest
RealFileUtils       = FileUtils
RealDir             = Dir
RealIO              = IO
RealPathname        = Pathname

def RealPathname(*args)
  RealPathname.new(*args)
end

def Pathname(*args)
  Pathname.new(*args)
end

# FakeFS module
module FakeFS
  class ActivationError < StandardError
    def initialize(current_state, required_state)
      states = current_state ? %i[without with] : %i[with without]
      super <<~ERROR
        Unable to activate #{states[0]} IO mocks as FakeFS is already activated #{states[1]}
      ERROR
    end
  end

  class << self
    def activated?(desired_io_mocks_state: nil)
      @activated ||= false
      @io_mocked ||= false

      @activated && (desired_io_mocks_state.nil? || desired_io_mocks_state == @io_mocked)
    end

    # unconditionally activate
    def activate!(io_mocks: false)
      raise ActivationError.new(@io_mocked, io_mocks) if activated? && @io_mocked != io_mocks

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

        if io_mocks
          remove_const(:IO)
          const_set(:IO, ::FakeFS::IO)
        end

        ::FakeFS::Kernel.hijack!
      end

      @io_mocked = io_mocks
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
        remove_const(:IO)
        remove_const(:Pathname)

        const_set(:Dir,       RealDir)
        const_set(:File,      RealFile)
        const_set(:FileTest,  RealFileTest)
        const_set(:FileUtils, RealFileUtils)
        const_set(:IO,        RealIO)
        const_set(:Pathname,  RealPathname)
        ::FakeFS::Kernel.unhijack!
      end

      @io_mocked = false
      @activated = false

      true
    end

    # unconditionally clear the fake filesystem
    def clear!
      ::FakeFS::FileSystem.clear
    end

    # present a fresh new fake filesystem to the block
    def with_fresh(io_mocks: false, &block)
      clear!
      with(io_mocks: io_mocks, &block)
    end

    # present the fake filesystem to the block
    def with(io_mocks: false)
      if activated?(desired_io_mocks_state: io_mocks)
        yield
      else
        begin
          activate!(io_mocks: io_mocks)
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
        io_mocked = @io_mocked
        begin
          deactivate!
          yield
        ensure
          activate!(io_mocks: io_mocked)
        end
      end
    end
  end
end

def FakeFS(io_mocks: false, &block)
  return ::FakeFS unless block
  ::FakeFS.with(io_mocks: io_mocks, &block)
end
