module FakeFS
  module FileUtils
    extend self

    def mkdir_p(path)
      FileSystem.add(path, FakeDir.new)
    end
    alias_method :mkpath, :mkdir_p

    def rmdir(list, options = {})
      list = [ list ] unless list.is_a?(Array)
      list.each do |l|
        parent = l.split('/')
        parent.pop
        raise Errno::ENOENT, "No such file or directory - #{l}" unless parent.join == "" || FileSystem.find(parent.join('/'))
        raise Errno::ENOENT, l unless FileSystem.find(l)
        raise Errno::ENOTEMPTY, l unless FileSystem.find(l).values.empty?
        rm(l)
      end
    end

    def rm(path)
      FileSystem.delete(path)
    end

    alias_method :rm_rf, :rm
    alias_method :rm_r, :rm
    alias_method :rm_f, :rm

    def ln_s(target, path, options = {})
      options = { :force => false }.merge(options)
      (FileSystem.find(path) and !options[:force]) ? raise(Errno::EEXIST, path) : FileSystem.delete(path)
      FileSystem.add(path, FakeSymlink.new(target))
    end
    def ln_sf(target, path)
      ln_s(target, path, { :force => true })
    end

    

    def cp(src, dest)
      dst_file = FileSystem.find(dest)
      src_file = FileSystem.find(src)

      if !src_file
        raise Errno::ENOENT, src
      end

      if File.directory? src_file
        raise Errno::EISDIR, src
      end

      if dst_file && File.directory?(dst_file)
        FileSystem.add(File.join(dest, src), src_file.entry.clone(dst_file))
      else
        FileSystem.delete(dest)
        FileSystem.add(dest, src_file.entry.clone)
      end
    end

    def cp_r(src, dest)
      # This error sucks, but it conforms to the original Ruby
      # method.
      raise "unknown file type: #{src}" unless dir = FileSystem.find(src)

      new_dir = FileSystem.find(dest)

      if new_dir && !File.directory?(dest)
        raise Errno::EEXIST, dest
      end

      if !new_dir && !FileSystem.find(dest+'/../')
        raise Errno::ENOENT, dest
      end

      # This last bit is a total abuse and should be thought hard
      # about and cleaned up.
      if new_dir
        if src[-2..-1] == '/.'
          dir.values.each{|f| new_dir[f.name] = f.clone(new_dir) }
        else
          new_dir[dir.name] = dir.entry.clone(new_dir)
        end
      else
        FileSystem.add(dest, dir.entry.clone)
      end
    end

    def mv(src, dest)
      if target = FileSystem.find(src)
        FileSystem.add(dest, target.entry.clone)
        FileSystem.delete(src)
      else
        raise Errno::ENOENT, src
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

    def touch(list, options={})
      Array(list).each do |f|
        directory = File.dirname(f)
        # FIXME this explicit check for '.' shouldn't need to happen
        if File.exists?(directory) || directory == '.'
          FileSystem.add(f, FakeFile.new)
        else
          raise Errno::ENOENT, f
        end
      end
    end

    def cd(dir)
      FileSystem.chdir(dir)
    end
    alias_method :chdir, :cd
  end
end
