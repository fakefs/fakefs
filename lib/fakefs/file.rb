module FakeFS
  class File
    PATH_SEPARATOR = '/'

    MODES = [
      READ_ONLY           = "r",
      READ_WRITE          = "r+",
      WRITE_ONLY          = "w",
      READ_WRITE_TRUNCATE = "w+",
      APPEND_WRITE_ONLY   = "a",
      APPEND_READ_WRITE   = "a+"
    ]

    FILE_CREATION_MODES = MODES - [READ_ONLY, READ_WRITE]

    READ_ONLY_MODES = [
      READ_ONLY
    ]

    WRITE_ONLY_MODES = [
      WRITE_ONLY,
      APPEND_WRITE_ONLY
    ]

    TRUNCATION_MODES = [
      WRITE_ONLY,
      READ_WRITE_TRUNCATE
    ]

    def self.extname(path)
      RealFile.extname(path)
    end

    def self.join(*parts)
      parts * PATH_SEPARATOR
    end

    def self.exist?(path)
      !!FileSystem.find(path)
    end

    class << self
      alias_method :exists?, :exist?

      # Assuming that everyone can read files
      alias_method :readable?, :exist?
    end

    def self.mtime(path)
      if exists?(path)
        FileSystem.find(path).mtime
      else
        raise Errno::ENOENT
      end
    end

    def self.size(path)
      read(path).length
    end

    def self.size?(path)
      if exists?(path) && !size(path).zero?
        true
      else
        nil
      end
    end

    def self.const_missing(name)
      RealFile.const_get(name)
    end

    def self.directory?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeDir
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeDir) : false
      end
    end

    def self.symlink?(path)
      if path.respond_to? :entry
        path.is_a? FakeSymlink
      else
        FileSystem.find(path).is_a? FakeSymlink
      end
    end

    def self.file?(path)
      if path.respond_to? :entry
        path.entry.is_a? FakeFile
      else
        result = FileSystem.find(path)
        result ? result.entry.is_a?(FakeFile) : false
      end
    end

    def self.expand_path(*args)
      RealFile.expand_path(*args)
    end

    def self.basename(*args)
      RealFile.basename(*args)
    end

    def self.dirname(path)
      RealFile.dirname(path)
    end

    def self.readlink(path)
      symlink = FileSystem.find(path)
      FileSystem.find(symlink.target).to_s
    end

    def self.open(path, mode=READ_ONLY, perm = 0644)
      if block_given?
        yield new(path, mode, perm)
      else
        new(path, mode, perm)
      end
    end

    def self.read(path)
      file = new(path)
      if file.exists?
        file.read
      else
        raise Errno::ENOENT
      end
    end

    def self.readlines(path)
      read(path).split("\n")
    end

    def self.link(source, dest)
      if directory?(source)
        raise Errno::EPERM, "Operation not permitted - #{source} or #{dest}"
      end

      if !exists?(source)
        raise Errno::ENOENT, "No such file or directory - #{source} or #{dest}"
      end

      if exists?(dest)
        raise Errno::EEXIST, "File exists - #{source} or #{dest}"
      end

      source = FileSystem.find(source)
      dest = FileSystem.add(dest, source.entry.clone)
      source.link(dest)

      0
    end

    def self.delete(file_name, *additional_file_names)
      if !exists?(file_name)
        raise Errno::ENOENT, "No such file or directory - #{file_name}"
      end

      FileUtils.rm(file_name)

      additional_file_names.each do |file_name|
        FileUtils.rm(file_name)
      end

      additional_file_names.size + 1
    end

    class << self
      alias_method :unlink, :delete
    end

    def self.symlink(source, dest)
      FileUtils.ln_s(source, dest)
    end

    def self.stat(file)
      File::Stat.new(file)
    end

    class Stat
      def initialize(file)
        if !File.exists?(file)
          raise(Errno::ENOENT, "No such file or directory - #{file}")
        end

        @file = file
      end

      def symlink?
        File.symlink?(@file)
      end

      def directory?
        File.directory?(@file)
      end

      def nlink
        FileSystem.find(@file).links.size
      end
    end

    attr_reader :path

    def initialize(path, mode = READ_ONLY, perm = nil)
      @path = path
      @mode = mode
      @file = FileSystem.find(path)
      @open = true
      @stream = StringIO.new(@file.content) if @file

      check_valid_mode
      file_creation_mode? ? create_missing_file : check_file_existence!
      truncate_file if truncation_mode?
    end

    def close
      @open = false
    end

    def read(chunk = nil)
      raise IOError, 'closed stream' unless @open
      raise IOError, 'not opened for reading' if write_only?
      @stream.read(chunk)
    end

    def rewind
      @stream.rewind
    end

    def exists?
      @file
    end

    def puts(*content)
      content.flatten.each do |obj|
        write(obj.to_s + "\n")
      end
    end

    def write(content)
      raise IOError, 'closed stream' unless @open
      raise IOError, 'not open for writing' if read_only?

      @file.content += content
    end
    alias_method :print, :write
    alias_method :<<, :write

    def flush; self; end

  private

    def check_file_existence!
      unless @file
        raise Errno::ENOENT, "No such file or directory - #{@file}"
      end
    end

    def check_valid_mode
      if !mode_in?(MODES)
        raise ArgumentError, "illegal access mode #{@mode}"
      end
    end

    def read_only?
      mode_in? READ_ONLY_MODES
    end

    def file_creation_mode?
      mode_in? FILE_CREATION_MODES
    end

    def write_only?
      mode_in? WRITE_ONLY_MODES
    end

    def truncation_mode?
      mode_in? TRUNCATION_MODES
    end

    def mode_in?(list)
      list.include?(@mode)
    end

    def create_missing_file
      if !File.exists?(@path)
        @file = FileSystem.add(path, FakeFile.new)
      end
    end

    def truncate_file
      @file.content = ""
    end
  end
end
