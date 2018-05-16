require 'stringio'

module FakeFS
  # FakeFS File class inherit StringIO
  class File < StringIO
    MODES = [
      READ_ONLY           = 'r'.freeze,
      READ_WRITE          = 'r+'.freeze,
      WRITE_ONLY          = 'w'.freeze,
      READ_WRITE_TRUNCATE = 'w+'.freeze,
      APPEND_WRITE_ONLY   = 'a'.freeze,
      APPEND_READ_WRITE   = 'a+'.freeze
    ].freeze

    FILE_CREATION_MODES = (MODES - [READ_ONLY, READ_WRITE]).freeze

    MODE_BITMASK = (
      RealFile::RDONLY |
      RealFile::WRONLY |
      RealFile::RDWR |
      RealFile::APPEND |
      RealFile::CREAT |
      RealFile::EXCL |
      RealFile::NONBLOCK |
      RealFile::TRUNC |
      (RealFile.const_defined?(:NOCTTY) ? RealFile::NOCTTY : 0) |
      (RealFile.const_defined?(:SYNC) ? RealFile::SYNC : 0)
    )

    FILE_CREATION_BITMASK = RealFile::CREAT

    def self.extname(path)
      RealFile.extname(path)
    end

    def self.join(*parts)
      RealFile.join(parts)
    end

    def self.path(file)
      RealFile.path(file)
    end

    def self.exist?(path)
      if File.symlink?(path)
        referent = File.expand_path(File.readlink(path), File.dirname(path))
        exist?(referent)
      else
        !FileSystem.find(path).nil?
      end
    end

    class << self
      alias exists? exist?

      # Assuming that everyone can read and write files
      alias readable? exist?
      alias writable? exist?

      # Assume nothing is sticky.
      def sticky?(_path)
        false
      end
    end

    def self.mtime(path)
      if exists?(path)
        FileSystem.find(path).mtime
      else
        raise Errno::ENOENT
      end
    end

    def self.ctime(path)
      if exists?(path)
        FileSystem.find(path).ctime
      else
        raise Errno::ENOENT
      end
    end

    def self.atime(path)
      if exists?(path)
        FileSystem.find(path).atime
      else
        raise Errno::ENOENT
      end
    end

    def self.utime(atime, mtime, *paths)
      paths.each do |path|
        if exists?(path)
          FileSystem.find(path).atime = atime
          FileSystem.find(path).mtime = mtime
        else
          raise Errno::ENOENT
        end
      end

      paths.size
    end

    def self.size(path)
      read(path).bytesize
    end

    def self.size?(path)
      size(path) if exists?(path) && !size(path).zero?
    end

    def self.zero?(path)
      exists?(path) && size(path) == 0
    end

    if RUBY_VERSION >= '2.4'
      class << self
        alias empty? zero?
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

    def self.ftype(filename)
      File.lstat(filename).ftype
    end

    def self.expand_path(file_name, dir_string = FileSystem.current_dir.to_s)
      RealFile.expand_path(file_name, RealFile.expand_path(dir_string, Dir.pwd))
    end

    def self.basename(*args)
      RealFile.basename(*args)
    end

    def self.dirname(path)
      RealFile.dirname(path)
    end

    def self.readlink(path)
      symlink = FileSystem.find(path)
      symlink.target
    end

    def self.read(path, *args)
      options = args[-1].is_a?(Hash) ? args.pop : {}
      length = args.empty? ? nil : args.shift
      offset = args.empty? ? 0 : args.shift
      file = new(path, options)

      raise Errno::ENOENT unless file.exists?
      raise Errno::EISDIR, path if directory?(path)

      FileSystem.find(path).atime = Time.now
      file.seek(offset)
      file.read(length)
    end

    def self.readlines(path)
      file = new(path)
      if file.exists?
        FileSystem.find(path).atime = Time.now
        file.readlines
      else
        raise Errno::ENOENT
      end
    end

    def self.foreach(path, *args, &block)
      file = new(path)
      if file.exists?
        FileSystem.find(path).atime = Time.now
        if block_given?
          file.each_line(*args, &block)
        else
          file.each_line(*args)
        end
      else
        raise Errno::ENOENT
      end
    end

    def self.rename(source, dest)
      if directory?(source) && file?(dest)
        raise Errno::ENOTDIR, "#{source} or #{dest}"
      elsif file?(source) && directory?(dest)
        raise Errno::EISDIR, "#{source} or #{dest}"
      elsif !exist?(dirname(dest))
        raise Errno::ENOENT, "#{source} or #{dest}"
      end

      if (target = FileSystem.find(source))
        if target.is_a?(FakeFS::FakeSymlink)
          File.symlink(target.target, dest)
        else
          FileSystem.add(dest, target.entry.clone)
        end

        FileSystem.delete(source)
      else
        raise Errno::ENOENT, "#{source} or #{dest}"
      end

      0
    end

    def self.link(source, dest)
      raise Errno::EPERM, "#{source} or #{dest}" if directory?(source)
      raise Errno::ENOENT, "#{source} or #{dest}" unless exists?(source)
      raise Errno::EEXIST, "#{source} or #{dest}" if exists?(dest)

      source = FileSystem.find(source)
      dest = FileSystem.add(dest, source.entry.clone)
      source.link(dest)

      0
    end

    def self.delete(*file_names)
      file_names.each do |file_name|
        raise Errno::ENOENT, file_name unless exists?(file_name)

        FileUtils.rm(file_name)
      end

      file_names.size
    end

    class << self
      alias unlink delete
    end

    def self.symlink(source, dest)
      FileUtils.ln_s(source, dest)
    end

    def self.stat(file)
      File::Stat.new(file)
    end

    def self.lstat(file)
      File::Stat.new(file, true)
    end

    def self.split(path)
      RealFile.split(path)
    end

    def self.chmod(mode_int, filename)
      FileSystem.find(filename).mode = 0o100000 + mode_int
    end

    # Not exactly right, returns true if the file is chmod +x for owner. In the
    # context of when you would use fakefs, this is usually what you want.
    def self.executable?(filename)
      file = FileSystem.find(filename)
      return false unless file
      (file.mode - 0o100000) & 0o100 != 0
    end

    def self.chown(owner_int, group_int, filename)
      file = FileSystem.find(filename)

      if owner_int && owner_int != -1
        owner_int.is_a?(Integer) || raise(TypeError, "can't convert String into Integer")
        file.uid = owner_int
      end
      if group_int && group_int != -1
        group_int.is_a?(Integer) || raise(TypeError, "can't convert String into Integer")
        file.gid = group_int
      end
    end

    def self.umask(*args)
      RealFile.umask(*args)
    end

    def self.binread(file, length = nil, offset = 0)
      File.read(file, length, offset, mode: 'rb:ASCII-8BIT')
    end

    def self.fnmatch?(pattern, path, flags = 0)
      RealFile.fnmatch?(pattern, path, flags)
    end

    class << self
      alias fnmatch fnmatch?
    end

    # FakeFS Stat class
    class Stat
      attr_reader :ctime, :mtime, :atime, :mode, :uid, :gid
      attr_reader :birthtime

      def initialize(file, lstat = false)
        raise(Errno::ENOENT, file) unless File.exist?(file)

        @file      = file
        @fake_file = FileSystem.find(@file)
        @__lstat   = lstat
        @ctime     = @fake_file.ctime
        @mtime     = @fake_file.mtime
        @atime     = @fake_file.atime
        @mode      = @fake_file.mode
        @uid       = @fake_file.uid
        @gid       = @fake_file.gid
        @birthtime =
          if @fake_file.respond_to?(:birthtime)
            @fake_file.birthtime
          else
            @fake_file.ctime
          end
      end

      def symlink?
        File.symlink?(@file)
      end

      def directory?
        File.directory?(@file)
      end

      def file?
        File.file?(@file)
      end

      def ftype
        return 'link' if symlink?
        return 'directory' if directory?
        'file'
      end

      # assumes, like above, that all files are readable and writable.
      def readable?
        true
      end

      def writable?
        true
      end

      # Assume nothing is sticky.
      def sticky?
        false
      end

      # World_writable and readable are platform dependent
      # usually comparing with S_IROTH defined on compilation (MRI)
      def world_writable?
        0o777
      end

      def world_readable?
        0o777
      end

      def nlink
        @fake_file.links.size
      end

      def size
        if @__lstat && symlink?
          @fake_file.target.size
        else
          File.size(@file)
        end
      end

      def zero?
        size == 0
      end

      include Comparable

      def <=>(other)
        @mtime <=> other.mtime
      end
    end

    attr_reader :path

    def initialize(path, mode = READ_ONLY, _perm = nil)
      @path = path
      @mode = mode.is_a?(Hash) ? (mode[:mode] || READ_ONLY) : mode
      @file = FileSystem.find(path)
      @autoclose = true

      check_modes!

      file_creation_mode? ? create_missing_file : check_file_existence!

      super(@file.content, @mode)
    end

    def exists?
      true
    end

    def write(str)
      val = super(str)
      @file.mtime = Time.now
      val
    end

    alias tell= pos=
    alias sysread read
    alias syswrite write

    undef_method :closed_read?
    undef_method :closed_write?
    undef_method :length
    undef_method :size
    undef_method :string
    undef_method :string=
    if RUBY_PLATFORM == 'java'
      undef_method :to_channel
      undef_method :to_outputstream
      undef_method :to_inputstream
      # JRuby 9.2.0.0
      undef_method :to_output_stream if respond_to?(:to_output_stream)
      undef_method :to_input_stream if respond_to?(:to_input_stream)
    end

    def is_a?(klass)
      RealFile.allocate.is_a?(klass)
    end

    def ioctl(*)
      raise NotImplementedError
    end

    def read_nonblock
      raise NotImplementedError
    end

    def stat
      self.class.stat(@path)
    end

    def lstat
      self.class.lstat(@path)
    end

    def sysseek(position, whence = SEEK_SET)
      seek(position, whence)
      pos
    end

    alias to_i fileno

    def to_io
      self
    end

    def write_nonblock(*)
      raise NotImplementedError
    end

    def readpartial(*)
      raise NotImplementedError
    end

    def atime
      self.class.atime(@path)
    end

    def ctime
      self.class.ctime(@path)
    end

    def flock(*)
      raise NotImplementedError
    end

    def mtime
      self.class.mtime(@path)
    end

    def chmod(mode_int)
      @file.mode = 0o100000 + mode_int
    end

    def chown(owner_int, group_int)
      return unless group_int && group_int != -1

      owner_int.is_a?(Integer) || raise(
        TypeError, "can't convert String into Integer"
      )
      @file.uid = owner_int

      group_int.is_a?(Integer) || raise(
        TypeError, "can't convert String into Integer"
      )
      @file.gid = group_int
    end

    def self.realpath(*args)
      RealFile.realpath(*args)
    end

    def binmode?
      raise NotImplementedError
    end

    def close_on_exec=(_bool)
      raise NotImplementedError
    end

    def close_on_exec?
      raise NotImplementedError
    end

    def to_path
      @path
    end

    def self.absolute_path(file_name, dir_name = Dir.getwd)
      RealFile.absolute_path(file_name, dir_name)
    end

    attr_accessor :autoclose

    def autoclose?
      @autoclose ? true : false
    end

    alias fdatasync flush

    def size
      File.size(@path)
    end

    def self.realdirpath(*args)
      RealFile.realdirpath(*args)
    end

    def advise(_advice, _offset = 0, _len = 0); end

    def self.write(filename, contents, offset = nil, open_args = {})
      offset, open_args = nil, offset if offset.is_a?(Hash)
      mode = offset ? 'a' : 'w'
      if open_args.any?
        if open_args[:open_args]
          args = [filename, *open_args[:open_args]]
        else
          mode = open_args[:mode] || mode
          args = [filename, mode, open_args]
        end
      else
        args = [filename, mode]
      end
      if offset
        open(*args) do |f| # rubocop:disable Security/Open
          f.seek(offset)
          f.write(contents)
        end
      else
        open(*args) do |f| # rubocop:disable Security/Open
          f << contents
        end
      end

      contents.length
    end

    def self.birthtime(path)
      if exists?(path)
        FileSystem.find(path).birthtime
      else
        raise Errno::ENOENT
      end
    end

    def birthtime
      self.class.birthtime(@path)
    end

    def read(length = nil, buf = '')
      read_buf = super(length, buf)
      read_buf.force_encoding('ASCII-8BIT') if binary_mode?
      read_buf
    end

    private

    def check_modes!
      StringIO.new('', @mode)
    end

    def binary_mode?
      @mode.is_a?(String) && (
        @mode.include?('b') ||
        @mode.include?('binary')
      ) && !@mode.include?('bom')
    end

    def check_file_existence!
      raise Errno::ENOENT, @path unless @file
    end

    def file_creation_mode?
      mode_in?(FILE_CREATION_MODES) || mode_in_bitmask?(FILE_CREATION_BITMASK)
    end

    def mode_in?(list)
      if @mode.respond_to?(:include?)
        list.any? do |element|
          @mode.include?(element)
        end
      end
    end

    def mode_in_bitmask?(mask)
      (@mode & mask) != 0 if @mode.is_a?(Integer)
    end

    # Create a missing file if the path is valid.
    #
    def create_missing_file
      raise Errno::EISDIR, path if File.directory?(@path)

      return if File.exist?(@path) # Unnecessary check, probably.
      dirname = RealFile.dirname @path

      unless dirname == '.'
        dir = FileSystem.find dirname

        raise Errno::ENOENT, path unless dir.is_a? FakeDir
      end

      @file = FileSystem.add(path, FakeFile.new)
    end
  end
end
