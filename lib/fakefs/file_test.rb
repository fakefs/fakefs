module FakeFS
  class FileTest
    def self.exist?(file_name)
      File.exist?(file_name)
    end
  end
end
