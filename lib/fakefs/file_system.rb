module FakeFS
  module FileSystem
    extend self

    def fs
      @fs ||= FakeDir.new('.')
    end

    def clear
      @fs = FakeDir.new('.')
      @current_dir = "/"
    end

    def files
      fs.values
    end

    def find(path, flags = 0)
      parts = path_parts(normalize_path(path))
      return fs if parts.empty? # '/'

      entries = find_recurser(fs, parts, flags).flatten

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
      @current_dir = "/"
    end

    def delete(path)
      if node = FileSystem.find(path)
        node.delete
      end
    end

    def chdir(dir, &blk)
      new_dir = normalize_path(dir)
      old_current_dir = @current_dir
      raise Errno::ENOENT, dir unless find(new_dir)
      @current_dir = new_dir

      if blk then
        begin
          blk.call
        ensure
          @current_dir = old_current_dir
        end
      end
    end

    def path_parts(path)
      path.split(File::PATH_SEPARATOR).reject { |part| part.empty? }
    end

    # expands path into an absolute path with no empty or dot components.
    # Uses File.expand_path to do this
    def normalize_path(path)
      File.expand_path(path)
    end

    attr_accessor :current_dir



    private

    def find_recurser(dir, parts, flags)
      return [] unless dir.respond_to? :[]

      pattern , *parts = parts
      matches = case pattern
      when '**'
        case parts
        when ['*']
          parts = [] # end recursion
          directories_under(dir, flags).map do |d|
            d.values.select{|f| f.is_a?(FakeFile) || is_a_directory_and_matches_flags?(f, 0)}
          end.flatten.uniq
        when []
          parts = [] # end recursion
          dir.values.flatten.uniq
        else
          directories_under(dir, flags)
        end
      else
        regexp_pattern = /\A#{pattern.gsub('?','.').gsub('*', '.*').gsub(/\{(.*?)\}/) { "(#{$1.gsub(',', '|')})" }}\Z/
        dir.reject {|k,v| regexp_pattern !~ k }.values
      end

      if parts.empty? # we're done recursing
        matches
      else
        matches.map{|entry| find_recurser(entry, parts, flags) }
      end
    end

    def directories_under(dir, flags)
      children = dir.values.select{|f| is_a_directory_and_matches_flags?(f, flags)}
      ([dir] + children + children.map{|c| directories_under(c, flags)}).flatten.uniq
    end

    def is_a_directory_and_matches_flags?(entry, flags)
      return entry.is_a?(FakeDir) if flags == File::FNM_DOTMATCH
      return entry.is_a?(FakeDir) && entry.name !~ /^\./ if flags != File::FNM_DOTMATCH
    end
  end
end
