RealFile            = File
RealFileTest        = FileTest
RealFileUtils       = FileUtils
RealDir             = Dir

module FakeFS
  def self.activate!
    Object.class_eval do
      remove_const(:Dir)
      remove_const(:File)
      remove_const(:FileTest)
      remove_const(:FileUtils)

      const_set(:Dir,       FakeFS::Dir)
      const_set(:File,      FakeFS::File)
      const_set(:FileUtils, FakeFS::FileUtils)
      const_set(:FileTest,  FakeFS::FileTest)
    end
    true
  end

  def self.deactivate!
    Object.class_eval do
      remove_const(:Dir)
      remove_const(:File)
      remove_const(:FileTest)
      remove_const(:FileUtils)

      const_set(:Dir,       RealDir)
      const_set(:File,      RealFile)
      const_set(:FileTest,  RealFileTest)
      const_set(:FileUtils, RealFileUtils)
    end
    true
  end
end

def FakeFS
  return ::FakeFS unless block_given?
  ::FakeFS.activate!
  yield
ensure
::FakeFS.deactivate!
end

