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

      # Assume nothing is sticky.
      def sticky?(_path)
        false
      end
    end

    def self.readable?(path)
      return false unless exist? path
      File.lstat(path).readable?
    end

    def self.writable?(path)
      return false unless exist? path
      File.lstat(path).writable?
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
      if directory?(path)
        64 + (32 * FileSystem.find(path).entries.size)
      else
        read(path).bytesize
      end
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
      raise Errno::EISDIR, path.to_s if directory?(path)

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
        raise Errno::ENOENT, file_name.to_s unless exists?(file_name)

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

    def self.chmod(new_mode, filename)
      # chmod's mode can either be passed in in absolute mode, or symbolic mode
      # for reference: https://ruby-doc.org/stdlib-2.2.2/libdoc/fileutils/rdoc/FileUtils.html#method-c-chmod
      # if the mode is passed in symbolic mode we must convert it to absolute mode
      is_absolute_mode = new_mode.is_a? Numeric
      unless is_absolute_mode
        current_mode = FileSystem.find(filename).mode
        new_mode = convert_symbolic_chmod_to_absolute(new_mode, current_mode)
      end
      FileSystem.find(filename).mode = 0o100000 + new_mode
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
        raise(Errno::ENOENT, file.to_s) unless File.exist?(file)

        @file      = file
        @fake_file = FileSystem.find(@file)
        @__lstat   = lstat
        @ctime     = @fake_file.ctime
        @mtime     = @fake_file.mtime
        @atime     = @fake_file.atime
        @mode      = @fake_file.mode
        @uid       = @fake_file.uid
        @gid       = @fake_file.gid
        @inode     = @fake_file.inode

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

      def readable?
        # a file is readable if, and only if, it has the following bits:
        #   4 ( read permission )
        #   5 ( read + execute permission )
        #   6 ( read + write permission )
        #   7 ( read + write + execute permission )
        # for each group we will isolate the wanted numbers ( for owner, world, or group )
        # and see if the third bit is set ( as that is the bit for read )
        read_bit = 4
        check_if_bit_set(read_bit)
      end

      def writable?
        # a file is writable if, and only if, it has the following bits:
        #   2 ( write permission )
        #   3 ( write + execute permission )
        #   6 ( read + write permission )
        #   7 ( read + write + execute permission )
        # for each group we will isolate the wanted numbers ( for owner, world, or group )
        # and see if the second bit is set ( as that is the bit for write )
        write_bit = 2
        check_if_bit_set(write_bit)
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

      def ino
        @inode.inode_num
      end

      include Comparable

      def <=>(other)
        @mtime <=> other.mtime
      end

      private

      def check_if_bit_set(bit)
        # get user's group and user ids
        # NOTE: I am picking `Process` over `Etc` as we use `Process`
        # when instaniating file classes. It may be worth it to ensure
        # our Process/Group detection scheme is robust in all cases
        uid = Process.uid
        gid = Process.gid

        # check if bit set for owner
        owner_bits = (@mode >> 6) & 0o7
        if uid == @uid
          # the user is locked out of the file if they are owner of the file
          # but do not have the bit set at the user level
          return true if owner_bits & bit == bit
          return false
        end

        # check if bit set for group
        group_bits = (@mode >> 3) & 0o7
        if gid == @gid
          # the user is locked out of the file if they are in the group that
          # owns the file but do not have the bit set at the group level
          return true if group_bits & bit == bit
          return false
        end

        # check if bit set for world
        world_bits = @mode & 0o7
        return true if world_bits & bit == bit

        false
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

    def string
      gets(nil)
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

    def chmod(new_mode)
      # chmod's mode can either be passed in in absolute mode, or symbolic mode
      # for reference: https://ruby-doc.org/stdlib-2.2.2/libdoc/fileutils/rdoc/FileUtils.html#method-c-chmod
      # if the mode is passed in symbolic mode we must convert it to absolute mode
      is_absolute_mode = new_mode.is_a? Numeric
      unless is_absolute_mode
        current_mode = @file.mode
        new_mode = convert_symbolic_chmod_to_absolute(new_mode, current_mode)
      end
      @file.mode = 0o100000 + new_mode
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
      read_buf&.force_encoding('ASCII-8BIT') if binary_mode?
      read_buf
    end

    def self.convert_symbolic_chmod_to_absolute(new_mode, current_mode)
      # mode always must be of form <GROUP1>=<FLAGS>,<GROUP2>=<FLAGS,...
      # e.g.: u=wr,go=x
      chmod_pairs = new_mode.split(',')

      # - duplicating groups is OK ( e.g.: 'ugouuoouu' is valid and is interpretted as 'ugo' )
      # - duplicating modes is OK ( e.g.: 'wwwwwwwww' is interpreted as 'w' )
      # - omitting the right hand side is interpretted as removing all permission
      # ( e.g.: 'ugo=' is really 'chmod 000' )
      # - omitting the left hand side is interpretted as all groups ( e.g.: '=rwx' is really 'ugo=rwx' )
      # - if we list a group more than once, we only apply the rightmost permissions
      # ( e.g.: 'ug=rx,g=x' is really 'u=r,g=x' )
      # - we cannot list any flags that are not 'rwx' ( e.g.: converting 'ug=rwx' to 'ug=7' is invalid )
      # or else an error is raised
      #   - in the example above, the following error is raised: 'invalid `perm' symbol in file mode: 7 (ArgumentError)'
      # - we cannot put in any groups that are not 'ugo' ( e.g.: listing groups as 'uzg=x' is invalid )
      # or else an error is raised
      #   - in the example above, the following error is raised: 'invalid `who' symbol in file mode: z (ArgumentError)'
      valid_groups_to_numeric_vals = { 'u' => 0o100, 'g' => 0o10, 'o' => 0o1 }

      # make sure we preload the current group values.
      # chmod works by calculating new permissions based off of existing permissions
      current_groups_to_vals = { 0o100 => 0o0, 0o10 => 0o0, 0o1 => 0o0 }
      [0o100, 0o10, 0o1].each do |group_num|
        perm_amt = get_perms_for_group(current_mode, group_num)
        current_groups_to_vals[group_num] = perm_amt
      end

      chmod_pairs.each do |pair|
        # see if we are dealing with +/- ( granting or removing permissions ) or = ( assigning permissions )
        # note that it IS valid to mix assignment and granting/revoking perissions ( things like u=wrx,g+x are valid )
        assign_perms = '='
        remove_perms = '-'
        add_perms = '+'
        assignment_mode = nil
        if pair.include? remove_perms
          assignment_mode = remove_perms
        elsif pair.include? add_perms
          assignment_mode = add_perms
        elsif pair.include? assign_perms
          assignment_mode = assign_perms
        end

        # if we can't find a mode, then raise an exception as real `chmod` would
        if assignment_mode.nil?
          raise ArgumentError, "Invalid file mode: #{mode}"
        end
        adding_removing_perms = [add_perms, remove_perms].include?(assignment_mode)

        groups = pair.rpartition(assignment_mode).first
        modes = pair.rpartition(assignment_mode).last

        # get the numeric chmod value associated with the symbolic entry
        chmod_perm_num = calculate_chmod_amt_for_mode modes

        # if we give no groups, then we are giving all groups
        if groups == ''
          if adding_removing_perms
            [0o100, 0o10, 0o1].each do |group_num|
              perm_amt = set_perms_for_group(current_groups_to_vals, group_num, assignment_mode, chmod_perm_num)
              current_groups_to_vals[group_num] = perm_amt
            end
          else
            [0o100, 0o10, 0o1].each do |group_num|
              current_groups_to_vals[group_num] = chmod_perm_num
            end
          end
        else
          # make sure there are no invalid flags in the groups and that we discard duplicates as chmod does
          given_groups = groups.split('')
          given_groups = given_groups.uniq
          given_groups.each do |specific_group|
            # ensure that the group is valid
            unless valid_groups_to_numeric_vals.key? specific_group
              raise ArgumentError, "Invalid `who' symbol in file mode: #{specific_group}"
            end

            # take the current chmod amt from earlier and associate that as the current chmod factor for the group
            # if we are adding or removing groups ( via +/- ) then we must make sure that we adjust
            # the current chmod perm number for the group
            group_num = valid_groups_to_numeric_vals[specific_group]
            adjusted_chmod = chmod_perm_num
            if adding_removing_perms
              adjusted_chmod = set_perms_for_group(current_groups_to_vals, group_num, assignment_mode, chmod_perm_num)
            end
            current_groups_to_vals[group_num] = adjusted_chmod
          end
        end
      end

      # return an octal chmod value for the value
      0o100 * current_groups_to_vals[0o100] + 0o10 * current_groups_to_vals[0o10] + current_groups_to_vals[0o1]
    end

    # return the group mode for group num based off the provided current_file_mode
    def self.get_perms_for_group(current_file_mode, group_num)
      # get the current recorded mode of the group and return it to the caller
      # note we don't shift for 'o' since that is the bottom 3 bits
      # note we multiply by 7 since the group num is 1, and octal represents digits 1-7 and we want all 3 bits
      current_group_mode = current_file_mode & (group_num * 7)
      if group_num == 0o100
        current_group_mode = current_group_mode >> 6
      elsif group_num == 0o10
        current_group_mode = current_group_mode >> 3
      end

      current_group_mode
    end

    # given the current chmod values for a file return the result of adding or removing chmod_perm_num from the
    # requested groups permissions ( so performing <GROUP>+<PERMS> or <GROUP>-<PERMS>
    def self.set_perms_for_group(current_groups_to_vals, group_num, assignment_mode, chmod_perm_num)
      # get the current recorded mode of the group
      current_group_mode = current_groups_to_vals[group_num]

      # now that we have the current value of the group, add or remove bits accordingly
      if assignment_mode == '+'
        current_group_mode | chmod_perm_num
      elsif assignment_mode == '-'
        current_group_mode & ~chmod_perm_num
      else
        raise ArguementError "Unknown assignment mode #{assignment_mode}"
      end
    end

    # given a list of modes [rwx] (a) ensure all modes are valid and (b) return the numeric value
    # associated with the modes
    def self.calculate_chmod_amt_for_mode(modes)
      valid_modes_to_numeric_vals = { 'r' => 0o4, 'w' => 0o2, 'x' => 0o1 }

      # if we give no modes, then we are removing all permission
      chmod_perm_num = 0o0
      if modes != ''
        # make sure there are no invalid flags in the modes and that we discard duplicates as chmod does
        given_modes = modes.split('')
        given_modes = given_modes.uniq
        given_modes.each do |specific_mode|
          # ensure that the mode is valid
          unless valid_modes_to_numeric_vals.key? specific_mode
            raise ArgumentError, "Invalid `perm' symbol in file mode: #{specific_mode}"
          end

          chmod_perm_num += valid_modes_to_numeric_vals[specific_mode]
        end
      end

      chmod_perm_num
    end

    # split the private class method decleration so rubocop doesn't complain the line is too long
    private_class_method :convert_symbolic_chmod_to_absolute, :calculate_chmod_amt_for_mode
    private_class_method :get_perms_for_group, :set_perms_for_group

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
      raise Errno::ENOENT, @path.to_s unless @file
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
      raise Errno::EISDIR, path.to_s if File.directory?(@path)

      return if File.exist?(@path) # Unnecessary check, probably.
      dirname = RealFile.dirname @path

      unless dirname == '.'
        dir = FileSystem.find dirname

        raise Errno::ENOENT, path.to_s unless dir.is_a? FakeDir
      end

      @file = FileSystem.add(path, FakeFile.new)
    end
  end
end
