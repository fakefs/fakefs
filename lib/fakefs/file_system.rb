module FakeFS
  module FileSystem
    extend self

    def dir_levels
      @dir_levels ||= []
    end

    def fs
      @fs ||= FakeDir.new('.')
    end

    def clear
      @dir_levels = nil
      @fs = nil
    end

    def files
      fs.values
    end

    def find(path)
      parts = path_parts(normalize_path(path))
      return fs if parts.empty? # '/'

      entries = find_recurser(fs, parts).flatten

      case entries.length
      when 0 then nil
      when 1 then entries.first
      else entries
      end
    end

    def add(path, object=FakeDir.new)
      parts = path_parts(normalize_path(path))

      d = parts[0...-1].inject(fs) do |dir, part|
        dir[part] ||= FakeDir.new(part, dir)
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
      files   = RealFile.file?(path) ? [path] : [path] + RealDir.glob(pattern, RealFile::FNM_DOTMATCH)

      files.each do |f|
        if RealFile.file?(f)
          FileUtils.mkdir_p(File.dirname(f))
          File.open(f, File::WRITE_ONLY) do |g|
            g.print RealFile.open(f){|h| h.read }
          end
        elsif RealFile.directory?(f)
          FileUtils.mkdir_p(f)
        elsif RealFile.symlink?(f)
          FileUtils.ln_s()
        end
      end
    end

    def delete(path)
      if node = FileSystem.find(path)
        node.delete
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

    private

    def find_recurser(dir, parts)
      return [] unless dir.respond_to? :[]

      pattern , *parts = parts
      matches = dir.reject {|k,v| /\A#{pattern.gsub('?','.').gsub('*', '.*')}\Z/ !~ k }.values

      if parts.empty? # we're done recursing
        matches
      else
        matches.map{|entry| find_recurser(entry, parts) }
      end
    end
  end
end
