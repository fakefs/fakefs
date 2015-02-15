module FakeFS
  # FileSystem module
  module FileSystem
    extend self

    def dir_levels
      @dir_levels ||= ['/']
    end

    def fs
      @fs ||= FakeDir.new('/')
    end

    def clear
      @dir_levels = nil
      @fs = nil
    end

    def files
      fs.entries
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

    def add(path, object = FakeDir.new)
      parts = path_parts(normalize_path(path))

      d = parts[0...-1].reduce(fs) do |dir, part|
        assert_dir dir[part] if dir[part]
        dir[part] ||= FakeDir.new(part, dir)
      end

      assert_dir d
      object.name = parts.last
      object.parent = d
      d[parts.last] ||= object
    end

    # copies directories and files from the real filesystem
    # into our fake one
    def clone(path, target = nil)
      path    = RealFile.expand_path(path)
      pattern = File.join(path, '**', '*')
      files   = if RealFile.file?(path)
                  [path]
                else
                  [path] + RealDir.glob(pattern, RealFile::FNM_DOTMATCH)
                end

      files.each do |f|
        target_path = target ? f.gsub(path, target) : f

        if RealFile.symlink?(f)
          FileUtils.ln_s(RealFile.readlink(f), f)
        elsif RealFile.file?(f)
          FileUtils.mkdir_p(File.dirname(f))
          File.open(target_path, File::WRITE_ONLY) do |g|
            g.print RealFile.read(f)
          end
        elsif RealFile.directory?(f)
          FileUtils.mkdir_p(target_path)
        end
      end
    end

    def delete(path)
      return unless (node = FileSystem.find(path))
      node.delete
      true
    end

    def chdir(dir, &blk)
      new_dir = find(dir)
      dir_levels.push dir if blk

      fail Errno::ENOENT, dir unless new_dir

      dir_levels.push dir unless blk
      blk.call if blk
    ensure
      dir_levels.pop if blk
    end

    def path_parts(path)
      drop_root(path.split(File::SEPARATOR)).reject(&:empty?)
    end

    def normalize_path(path)
      if Pathname.new(path).absolute?
        RealFile.expand_path(path)
      else
        parts = dir_levels + [path]
        RealFile.expand_path(parts.reduce do |base, part|
                               Pathname(base) + part
                             end.to_s)
      end
    end

    def current_dir
      find('.')
    end

    private

    def drop_root(path_parts)
      # we need to remove parts from root dir at least for windows and jruby
      return path_parts if path_parts.nil? || path_parts.empty?
      root = RealFile.expand_path('/').split(File::SEPARATOR).first
      path_parts.shift if path_parts.first == root
      path_parts
    end

    def find_recurser(dir, parts)
      return [] unless dir.respond_to? :[]

      pattern, *parts = parts
      matches = case pattern
                when '**'
                  case parts
                  when ['*']
                    parts = [] # end recursion
                    directories_under(dir).map do |d|
                      d.entries.select do |f|
                        (f.is_a?(FakeFile) || f.is_a?(FakeDir)) &&
                        f.name.match(/\A(?!\.)/)
                      end
                    end.flatten.uniq
                  when []
                    parts = [] # end recursion
                    dir.entries.flatten.uniq
                  else
                    directories_under(dir)
                  end
                else
                  regex_body = pattern.gsub('.', '\.')
                               .gsub('?', '.')
                               .gsub('*', '.*')
                               .gsub('(', '\(')
                               .gsub(')', '\)')
                               .gsub(/\{(.*?)\}/) do
                                 "(#{Regexp.last_match[1].gsub(',', '|')})"
                               end
                               .gsub(/\A\./, '(?!\.).')
                  dir.matches(/\A#{regex_body}\Z/)
                end

      if parts.empty? # we're done recursing
        matches
      else
        matches.map { |entry| find_recurser(entry, parts) }
      end
    end

    def directories_under(dir)
      children = dir.entries.select { |f| f.is_a? FakeDir }
      ([dir] + children + children.map { |c| directories_under(c) })
        .flatten.uniq
    end

    def assert_dir(dir)
      fail Errno::EEXIST, dir.name unless dir.is_a?(FakeDir)
    end
  end
end
