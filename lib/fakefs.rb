require 'fileutils'
require 'pathname'

RealFile = File
RealFileUtils = FileUtils
RealDir = Dir

module FakeFS
  module FileUtils
    extend self

    def mkdir_p(path)
      FileSystem.add(path, MockDir.new)
    end

    def rm(path)
      FileSystem.delete(path)
    end
    alias_method :rm_rf, :rm

    def ln_s(target, path)
      FileSystem.add(path, MockSymlink.new(target))
    end

    def cp_r(src, dest)
      if dir = FileSystem.find(src)
        FileSystem.add(dest, dir.entry)
      end
    end

    def mv(src, dest)
      if target = FileSystem.find(src)
        FileSystem.add(dest, target.entry)
        FileSystem.delete(src)
      end
    end

    def chown(user, group, list, options={})
      list = Array(list)
      list.each do |f|
        unless File.exists?(f)
          raise Errno::ENOENT, f
        end
      end
      list
    end

    def chown_R(user, group, list, options={})
      chown(user, group, list, options={})
    end
  end

  class File
    PATH_SEPARATOR = '/'

    def self.join(*parts)
      parts * PATH_SEPARATOR
    end

    def self.exists?(path)
      FileSystem.find(path) || false
    end

    def self.directory?(path)
      FileSystem.find(path).is_a? MockDir
    end

    def self.symlink?(path)
      FileSystem.find(path).is_a? MockSymlink
    end

    def self.file?(path)
      FileSystem.find(path).is_a? MockFile
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

    def self.open(path, mode='r')
      if block_given?
        yield new(path, mode)
      else
        new(path, mode)
      end
    end

    def self.read(path)
      new(path).read
    end

    def self.readlines(path)
      read(path).split("\n")
    end

    attr_reader :path
    def initialize(path, mode = nil)
      @path = path
      @mode = mode
      @file = FileSystem.find(path)
    end

    def read
      @file.content
    end

    def puts(content)
      write(content + "\n")
    end

    def write(content)
      if !File.exists?(@path)
        @file = FileSystem.add(path, MockFile.new)
      end

      @file.content += content
    end
    alias_method :print, :write
  end

  class Dir
    def self.glob(pattern)
      if pattern[-1,1] == '*'
        blk = proc { |entry| entry.to_s }
      else
        blk = proc { |entry| entry[1].parent.to_s }
      end
      (FileSystem.find(pattern) || []).map(&blk).uniq.sort
    end

    def self.[](pattern)
      glob(pattern)
    end

    def self.chdir(dir, &blk)
      FileSystem.chdir(dir, &blk)
    end
  end

  module FileSystem
    extend self

    def dir_levels
      @dir_levels ||= []
    end

    def fs
      @fs ||= MockDir.new('.')
    end

    def clear
      @dir_levels = []
      @fs = nil
    end

    def files
      fs.values
    end

    def find(path)
      parts = path_parts(normalize_path(path))

      target = parts[0...-1].inject(fs) do |dir, part|
        dir[part] || {}
      end

      case parts.last
      when '*'
        target.values
      else
        target[parts.last]
      end
    end

    def add(path, object=MockDir.new)
      parts = path_parts(normalize_path(path))

      d = parts[0...-1].inject(fs) do |dir, part|
        dir[part] ||= MockDir.new(part, dir)
      end

      object.name = parts.last
      object.parent = d
      d[parts.last] ||= object
    end

    # copies directories and files from the real filesystem
    # into our fake one
    def clone(path)
      path    = File.expand_path(path)
      pattern = File.join(path, '**', '*')
      files   = RealFile.file?(path) ? [path] : RealDir.glob(pattern)

      files.each do |f|
        if RealFile.file?(f)
          FileUtils.mkdir_p(File.dirname(f))
          File.open(f, 'w') do |f|
            f.puts RealFile.read(f)
          end
        elsif RealFile.directory?(f)
          FileUtils.mkdir_p(f)
        elsif RealFile.symlink?(f)
          FileUtils.ln_s()
        end
      end
    end

    def delete(path)
      if dir = FileSystem.find(path)
        dir.parent.delete(dir.name)
      end
    end

    def chdir(dir, &blk)
      new_dir = find(dir)
      dir_levels.push dir if blk

      raise Errno::ENOENT, dir unless new_dir

      dir_levels.push dir if !blk
      blk.call if blk
    ensure
      dir_levels.pop if blk
    end

    def path_parts(path)
      path.split(File::PATH_SEPARATOR).reject { |part| part.empty? }
    end

    def normalize_path(path)
      if Pathname.new(path).absolute?
        File.expand_path(path)
      else
        parts = dir_levels + [path]
        File.expand_path(File.join(*parts))
      end
    end

    def current_dir
      find(normalize_path('.'))
    end
  end

  class MockFile
    attr_accessor :name, :parent, :content
    def initialize(name = nil, parent = nil)
      @name = name
      @parent = parent
      @content = ''
    end

    def entry
      self
    end

    def to_s
      File.join(parent.to_s, name)
    end
  end

  class MockDir < Hash
    attr_accessor :name, :parent

    def initialize(name = nil, parent = nil)
      @name = name
      @parent = parent
    end

    def entry
      self
    end

    def to_s
      if parent && parent.to_s != '.'
        File.join(parent.to_s, name)
      elsif parent && parent.to_s == '.'
        "#{File::PATH_SEPARATOR}#{name}"
      else
        name
      end
    end
  end

  class MockSymlink
    attr_accessor :name, :target
    alias_method  :to_s, :name

    def initialize(target)
      @target = target
    end

    def inspect
      "symlink(#{target.split('/').last})"
    end

    def entry
      FileSystem.find(target)
    end

    def method_missing(*args, &block)
      entry.send(*args, &block)
    end
  end
end

Object.class_eval do
  remove_const(:Dir)
  remove_const(:File)
  remove_const(:FileUtils)
end

File = FakeFS::File
FileUtils = FakeFS::FileUtils
Dir = FakeFS::Dir
