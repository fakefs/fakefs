module FakeFS
  # FileUtils module
  module FileUtils
    extend self

    def mkdir_p(list, options = {})
      list = [list] unless list.is_a?(Array)
      list.each do |path|
        # FileSystem.add call adds all the necessary parent directories but
        # can't set their mode. Thus, we have to collect created directories
        # here and set the mode later.
        if options[:mode]
          created_dirs = []
          dir = path

          until Dir.exist?(dir)
            created_dirs << dir
            dir = File.dirname(dir)
          end
        end

        FileSystem.add(path, FakeDir.new)

        next unless options[:mode]
        created_dirs.each do |d|
          File.chmod(options[:mode], d)
        end
      end
    end

    alias mkpath mkdir_p
    alias makedirs mkdir_p

    def mkdir(list, _ignored_options = {})
      list = [list] unless list.is_a?(Array)
      list.each do |path|
        parent = path.to_s.split('/')
        parent.pop
        unless parent.join == '' || parent.join == '.' || FileSystem.find(parent.join('/'))
          raise Errno::ENOENT, path.to_s
        end
        raise Errno::EEXIST, path.to_s if FileSystem.find(path)
        FileSystem.add(path, FakeDir.new)
      end
    end

    def rmdir(list, _options = {})
      list = [list] unless list.is_a?(Array)
      list.each do |l|
        parent = l.to_s.split('/')
        parent.pop
        raise Errno::ENOENT, l.to_s unless parent.join == '' || FileSystem.find(parent.join('/'))
        raise Errno::ENOENT, l.to_s unless FileSystem.find(l)
        raise Errno::ENOTEMPTY, l.to_s unless FileSystem.find(l).empty?
        rm(l)
      end
    end

    def rm(list, options = {})
      Array(list).each do |path|
        FileSystem.delete(path) ||
          (!options[:force] && raise(Errno::ENOENT, path.to_s))
      end
    end
    alias rm_r rm
    alias remove rm

    def rm_f(list, options = {})
      rm(list, options.merge(force: true))
    end

    def rm_rf(list, options = {})
      rm_r(list, options.merge(force: true))
    end
    alias rmtree rm_rf
    alias safe_unlink rm_f

    def remove_entry_secure(path, force = false)
      rm_rf(path, force: force)
    end

    def ln_s(target, path, options = {})
      options = { force: false }.merge(options)
      raise(Errno::EEXIST, path.to_s) if FileSystem.find(path) && !options[:force]
      FileSystem.delete(path)

      if !options[:force] && !Dir.exist?(File.dirname(path))
        raise Errno::ENOENT, path.to_s
      end

      FileSystem.add(path, FakeSymlink.new(target))
    end

    def ln_sf(target, path)
      ln_s(target, path, force: true)
    end

    alias symlink ln_s

    def cp(src, dest, options = {})
      raise Errno::ENOTDIR, dest.to_s if src.is_a?(Array) && !File.directory?(dest)

      raise Errno::ENOENT, dest.to_s unless File.exist?(dest) || File.exist?(File.dirname(dest))

      # handle `verbose' flag
      RealFileUtils.cp src, dest, options.merge(noop: true)

      # handle `noop' flag
      return if options[:noop]

      Array(src).each do |source|
        dst_file = FileSystem.find(dest)
        src_file = FileSystem.find(source)

        raise Errno::ENOENT, source.to_s unless src_file

        if dst_file && File.directory?(dst_file)
          FileSystem.add(
            File.join(dest, File.basename(source)), src_file.entry.clone(dst_file)
          )
        else
          FileSystem.delete(dest)
          FileSystem.add(dest, src_file.entry.clone)
        end
      end

      nil
    end

    alias copy cp

    def copy_file(src, dest, _preserve = false, _dereference = true)
      # Not a perfect match, but similar to what regular FileUtils does.
      cp(src, dest)
    end

    def copy_entry(src, dest, preserve = false, dereference_root = false, remove_destination = false)
      cp_r(
        src, dest,
        preserve: preserve,
        dereference_root: dereference_root,
        remove_destination: remove_destination
      )
    end

    def cp_r(src, dest, options = {})
      # handle `verbose' flag
      RealFileUtils.cp_r src, dest, options.merge(noop: true)

      # handle `noop' flag
      return if options[:noop]

      Array(src).each do |source|
        dir = FileSystem.find(source)
        raise Errno::ENOENT, source.to_s unless dir

        new_dir = FileSystem.find(dest)
        raise Errno::EEXIST, dest.to_s if new_dir && !File.directory?(dest)
        raise Errno::ENOENT, dest.to_s if !new_dir && !FileSystem.find(dest.to_s + '/../')

        # This last bit is a total abuse and should be thought hard
        # about and cleaned up.
        if new_dir
          if src.to_s[-2..-1] == '/.'
            dir.entries.each { |f| new_dir[f.name] = f.clone(new_dir) }
          else
            new_dir[dir.name] = dir.entry.clone(new_dir)
          end
        else
          FileSystem.add(dest, dir.entry.clone)
        end
      end

      nil
    end

    def mv(src, dest, options = {})
      # handle `verbose' flag
      RealFileUtils.mv src, dest, options.merge(noop: true)

      # handle `noop' flag
      return if options[:noop]

      Array(src).each do |path|
        if (target = FileSystem.find(path))
          dest_path =
            if File.directory?(dest)
              File.join(dest, File.basename(path))
            else
              dest
            end
          if File.directory?(dest_path)
            raise Errno::EEXIST, dest_path.to_s unless options[:force]
          elsif File.directory?(File.dirname(dest_path))
            FileSystem.delete(dest_path)
            FileSystem.delete(path)
            FileSystem.add(dest_path, target.entry.clone)
          else
            raise Errno::ENOENT, dest_path.to_s unless options[:force]
          end
        else
          raise Errno::ENOENT, path.to_s
        end
      end

      nil
    end

    alias move mv

    def chown(user, group, list, _options = {})
      list = Array(list)
      list.each do |f|
        if File.exist?(f)
          uid =
            if user
              user.to_s =~ /\d+/ ? user.to_i : Etc.getpwnam(user).uid
            end
          gid =
            if group
              group.to_s =~ /\d+/ ? group.to_i : Etc.getgrnam(group).gid
            end
          File.chown(uid, gid, f)
        else
          raise Errno::ENOENT, f.to_s
        end
      end
      list
    end

    def chown_R(user, group, list, _options = {})
      list = Array(list)
      list.each do |file|
        chown(user, group, file)
        [FileSystem.find("#{file}/**/**")].flatten.each do |f|
          chown(user, group, f.to_s)
        end
      end
      list
    end

    def chmod(mode, list, _options = {})
      list = Array(list)
      list.each do |f|
        if File.exist?(f)
          File.chmod(mode, f)
        else
          raise Errno::ENOENT, f.to_s
        end
      end
      list
    end

    def chmod_R(mode, list, _options = {})
      list = Array(list)
      list.each do |file|
        chmod(mode, file)
        [FileSystem.find("#{file}/**/**")].flatten.each do |f|
          chmod(mode, f.to_s)
        end
      end
      list
    end

    def touch(list, options = {})
      Array(list).each do |f|
        if (fs = FileSystem.find(f))
          now = Time.now
          fs.mtime = options[:mtime] || now
          fs.atime = now
        else
          file = File.open(f, 'w')
          file.close

          if (mtime = options[:mtime])
            fs = FileSystem.find(f)
            fs.mtime = mtime
          end
        end
      end
    end

    def cd(dir, &block)
      FileSystem.chdir(dir, &block)
    end
    alias chdir cd

    def compare_file(file1, file2)
      # we do a strict comparison of both files content
      File.readlines(file1) == File.readlines(file2)
    end

    alias cmp compare_file
    alias identical? compare_file

    def uptodate?(new, old_list)
      return false unless File.exist?(new)
      new_time = File.mtime(new)
      old_list.each do |old|
        if File.exist?(old)
          return false unless new_time > File.mtime(old)
        end
      end
      true
    end
  end
end
