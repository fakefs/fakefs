require 'fakefs/fileutils'

module FakeFS
  class Dir
    def Dir::mktmpdir(prefix_suffix=nil, tmpdir=nil)
      # This code has been borrowed from Rubinius. Thanks, guys! :-)
      
      case prefix_suffix
      when nil
        prefix = "d"
        suffix = ""
      when String
        prefix = prefix_suffix
        suffix = ""
      when Array
        prefix = prefix_suffix[0]
        suffix = prefix_suffix[1]
      else
        raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
      end
      tmpdir ||= Dir.tmpdir
      t = Time.now.strftime("%Y%m%d")
      n = nil
      begin
        path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
        path << "-#{n}" if n
        path << suffix
        Dir.mkdir(path, 0700)
      rescue Errno::EEXIST
        n ||= 0
        n += 1
        retry
      end

      if block_given?
        begin
          yield path
        ensure
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
  end
end
