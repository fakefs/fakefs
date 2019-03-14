module FakeFS
  # FileTest
  module FileTest
    extend self

    def directory?(file_name)
      File.directory?(file_name)
    end

    def executable?(file_name)
      File.executable?(file_name)
    end

    def exist?(file_name)
      File.exist?(file_name)
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

    def sticky?(file_name)
      File.sticky?(file_name)
    end

    def symlink?(file_name)
      File.symlink?(file_name)
    end

    def world_readable?(file_name)
      File.new(file_name).stat.world_readable?
    end

    def world_writable?(file_name)
      File.new(file_name).stat.world_writable?
    end

    def writable?(file_name)
      File.writable?(file_name)
    end

    def zero?(file_name)
      File.zero?(file_name)
    end

    if RUBY_VERSION > '2.4'
      class << self
        alias empty? zero?
      end
    end
  end
end
