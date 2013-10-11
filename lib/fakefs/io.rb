module FakeFS
  class IO < IO
    def self.write(file_name, content)
      File.open(file_name, 'w') do |file|
        file.write(content)
      end
    end

    def self.read(file_name)
      File.open(file_name, 'rb').read
    end
   end
end

