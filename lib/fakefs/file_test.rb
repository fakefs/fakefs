module FakeFS
  # FileTest
  module FileTest
    extend self

    def exist?(file_name)
      File.exist?(file_name)
    end

    def directory?(file_name)
      File.directory?(file_name)
    end

    def file?(file_name)
      File.file?(file_name)
    end

    def size?(file_name)
      File.size?(file_name)
    end

    def readable?(file_name)
      File.readable?(file_name)
    end

    def writable?(file_name)
      File.writable?(file_name)
    end

    def zero?(file_name)
      File.zero?(file_name)
    end

    if RUBY_VERSION > '2.4'
      class << self
        alias :empty? :zero?
      end
    end
  end
end
