RealFile            = File
RealFileTest        = FileTest
RealFileUtils       = FileUtils
RealDir             = Dir

module FakeFS
  class << self
    def activate!
      remove_constants

      Object.class_eval do
        const_set(:Dir,       FakeFS::Dir)
        const_set(:File,      FakeFS::File)
        const_set(:FileUtils, FakeFS::FileUtils)
        const_set(:FileTest,  FakeFS::FileTest)
      end
      true
    end

    def deactivate!
      remove_constants

      Object.class_eval do
        const_set(:Dir,       RealDir)
        const_set(:File,      RealFile)
        const_set(:FileTest,  RealFileTest)
        const_set(:FileUtils, RealFileUtils)
      end
      true
    end

    private

      def modified_constants
        [:Dir, :File, :FileUtils, :FileTest].sort!
      end

      def remove_constants
        Object.class_exec(modified_constants) do |constants|
          constants.map { |c| remove_const(c) }
        end
      end
  end
end

def FakeFS
  return ::FakeFS unless block_given?
  ::FakeFS.activate!
  yield
ensure
::FakeFS.deactivate!
end

