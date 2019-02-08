require 'English'

module FakeFS
  # FakeFs Dir class
  class Dir
    include Enumerable
    attr_reader :path

    def self._check_for_valid_file(path)
      raise Errno::ENOENT, path.to_s unless FileSystem.find(path)
    end

    def initialize(string)
      self.class._check_for_valid_file(string)

      @path     = FileSystem.normalize_path(string)
      @open     = true
      @pointer  = 0
      @contents = ['.', '..'] + FileSystem.find(@path).entries
      @inode    = FakeInode.new(self)
    end

    def close
      @open = false
      @pointer = nil
      @contents = nil
      nil
    end

    def each
      if block_given?
        while (f = read)
          yield f
        end
      else
        @contents.map { |entry| entry_to_relative_path(entry) }.each
      end
    end

    def pos
      @pointer
    end

    def pos=(integer)
      @pointer = integer
    end

    def read
      raise IOError, 'closed directory' unless @pointer
      entry = @contents[@pointer]
      @pointer += 1
      entry_to_relative_path(entry) if entry
    end

    def rewind
      @pointer = 0
    end

    def seek(integer)
      raise IOError, 'closed directory' if @pointer.nil?
      @pointer = integer
      @contents[integer]
    end

    def self.[](*pattern)
      glob pattern
    end

    def self.exists?(path)
      File.exist?(path) && File.directory?(path)
    end

    def self.chdir(dir, &blk)
      FileSystem.chdir(dir, &blk)
    end

    def self.chroot(_string)
      raise NotImplementedError
    end

    def self.delete(string)
      _check_for_valid_file(string)
      raise Errno::ENOTEMPTY, string.to_s unless FileSystem.find(string).empty?

      FileSystem.delete(string)
    end

    def self.entries(dirname, _opts = {})
      _check_for_valid_file(dirname)

      Dir.new(dirname).map { |file| File.basename(file) }
    end

    def self.children(dirname, opts = {})
      entries(dirname, opts) - ['.', '..']
    end

    def self.each_child(dirname, &_block)
      Dir.open(dirname) do |file|
        next if ['.', '..'].include?(file)
        yield file
      end
    end

    if RUBY_VERSION >= '2.4'
      def self.empty?(dirname)
        _check_for_valid_file(dirname)
        if File.directory?(dirname)
          Dir.new(dirname).count <= 2
        else
          false
        end
      end
    end

    def self.foreach(dirname, &_block)
      Dir.open(dirname) { |file| yield file }
    end

    def self.glob(pattern, flags = 0, &block)
      matches_for_pattern = lambda do |matcher|
        [FileSystem.find(matcher, flags, true) || []].flatten.map do |e|
          if Dir.pwd.match(%r{\A/?\z}) ||
             !e.to_s.match(%r{\A#{Dir.pwd}/?})
            e.to_s
          else
            e.to_s.match(%r{\A#{Dir.pwd}/?}).post_match
          end
        end.sort
      end

      files =
        if pattern.is_a?(Array)
          pattern.map do |matcher|
            matches_for_pattern.call matcher
          end.flatten
        else
          matches_for_pattern.call pattern
        end

      block_given? ? files.each { |file| block.call(file) } : files
    end

    def self.home(user = nil)
      RealDir.home(user)
    end

    def self.mkdir(string, _integer = 0)
      FileUtils.mkdir(string)
    end

    def self.open(string, &_block)
      if block_given?
        Dir.new(string).each { |file| yield(file) }
      else
        Dir.new(string)
      end
    end

    def self.tmpdir
      '/tmp'
    end

    def self.pwd
      FileSystem.current_dir.to_s
    end

    # Tmpname module
    module Tmpname # :nodoc:
      module_function

      def tmpdir
        Dir.tmpdir
      end

      def make_tmpname(prefix_suffix, suffix)
        case prefix_suffix
        when String
          prefix = prefix_suffix
          suffix = ''
        when Array
          prefix = prefix_suffix[0]
          suffix = prefix_suffix[1]
        else
          raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
        end
        t = Time.now.strftime('%Y%m%d')
        path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
        path << "-#{suffix}" if suffix
        path << suffix
      end

      def create(basename, *rest)
        if (opts = Hash.try_convert(rest[-1]))
          opts = opts.dup if rest.pop.equal?(opts)
          max_try = opts.delete(:max_try)
          opts = [opts]
        else
          opts = []
        end
        tmpdir, = *rest
        if $SAFE > 0 && tmpdir.tainted?
          tmpdir = '/tmp'
        else
          tmpdir ||= self.tmpdir
        end
        n = nil
        begin
          path = File.join(tmpdir, make_tmpname(basename, n))
          yield(path, n, *opts)
        rescue Errno::EEXIST
          n ||= 0
          n += 1
          retry if !max_try || n < max_try
          raise "cannot generate temporary name using `#{basename}' " \
            "under `#{tmpdir}'"
        end
        path
      end
    end

    def ino
      @inode.inode_num
    end

    # This code has been borrowed from Rubinius
    def self.mktmpdir(prefix_suffix = nil, tmpdir = nil)
      case prefix_suffix
      when nil
        prefix = 'd'
        suffix = ''
      when String
        prefix = prefix_suffix
        suffix = ''
      when Array
        prefix = prefix_suffix[0]
        suffix = prefix_suffix[1]
      else
        raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
      end

      t = Time.now.strftime('%Y%m%d')
      n = nil

      begin
        path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
        path << "-#{n}" if n
        path << suffix
        mkdir(path, 0o700)
      rescue Errno::EEXIST
        n ||= 0
        n += 1
        retry
      end

      if block_given?
        begin
          yield path
        ensure
          require 'fileutils'
          # This here was using FileUtils.remove_entry_secure instead of just
          # .rm_r. However, the security concerns that apply to
          # .rm_r/.remove_entry_secure shouldn't apply to a test fake
          # filesystem. :^)
          FileUtils.rm_r path
        end
      else
        path
      end
    end

    private

    def entry_to_relative_path(entry)
      filename = entry.to_s
      filename.start_with?("#{path}/") ? filename[path.size + 1..-1] : filename
    end

    class << self
      alias getwd pwd
      alias rmdir delete
      alias unlink delete
      alias exist? exists?
    end
  end
end
