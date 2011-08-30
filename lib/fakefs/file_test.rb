module FakeFS
  class FileTest
    def self.exist?(file_name)
      File.exist?(file_name)
    end

    def self.directory?(file_name)
      File.directory?(file_name)
    end

    def self.file?(file_name)
      File.file?(file_name)
    end
  end
end
