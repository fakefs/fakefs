require "stringio"

module FakeFS
  
  module Require
    @active = false
    
    # Activates faked #require
    #
    # = Options
    # 
    # * :fallback => true # activates the fallback to Kernel#require
    # * :autoload => true # activates faked #autoload, #autoload? and #const_missing
    # * :load => true     # activates faked #load
    def self.activate! opts = {}
      return if active?
      
      @active = true
      
      @opts = {
        :fallback => false,
        :autoload => false,
        :load => false,
      }.merge opts
      
      Kernel.class_eval do
        alias_method :fakefs_original_require, :require
        alias_method :require, :fakefs_require
      end
      
      Module.class_eval do
        alias_method :fakefs_original_autoload, :autoload
        alias_method :autoload, :fakefs_autoload
        
        alias_method :fakefs_original_autoload?, :autoload?
        alias_method :autoload?, :fakefs_autoload?
        
        alias_method :fakefs_original_const_missing, :const_missing
        alias_method :const_missing, :fakefs_const_missing
      end if @opts[:autoload]
      
      Kernel.class_eval do
        alias_method :fakefs_original_load, :load
        alias_method :load, :fakefs_load
      end if @opts[:load]
    end
    
    # Deactivates the faked methods
    def self.deactivate!
      return unless active?
      
      @active = false
      
      Kernel.class_eval do
        alias_method :require, :fakefs_original_require
      end
      
      Module.class_eval do
        alias_method :autoload, :fakefs_original_autoload
        alias_method :autoload?, :fakefs_original_autoload?
        alias_method :const_missing, :fakefs_original_const_missing
      end if @opts[:autoload]
      
      Kernel.class_eval do
        alias_method :load, :fakefs_original_load
      end if @opts[:load]
      
      @opts = nil
    end
    
    # Returns whether FakeFS::Require is active
    def self.active?
      @active
    end
    
    # Returns the options passed to ::activate!
    def self.opts
      @opts
    end
    
    # Returns a hash containing autoload data
    def self.autoloadable
      @autoloadable ||= {}
    end
    
    # Clears the autoload data hash
    def self.clear
      @autoloadable = {}
    end
    
    # Resolves the passed filename to a path
    def self.resolve fn
      found = nil
      if fn[0...1] == "/"
        found = fn if File.exist? fn
      else
        $LOAD_PATH.each do |p|
          path = p + "/" + fn
          found = path if File.exist? path
        end
      end
      
      return found
    end
    
    # Faked #require (see Kernel#require)
    def fakefs_require fn
      fn = fn.to_s
      orig_fn = fn.dup
      
      fn = fn + ".rb" unless fn[-3..-1] == ".rb"
      path = FakeFS::Require.resolve fn
      
      if path
        return false if $LOADED_FEATURES.include? path
        
        File.open(path, "r") {|f| Object.class_eval f.read, fn, 1 }
        $LOADED_FEATURES << path
        return true
      elsif FakeFS::Require.opts[:fallback]
        opts = FakeFS::Require.opts
        begin
          FakeFS.deactivate!
          FakeFS::Require.deactivate!
          return fakefs_original_require orig_fn
        ensure
          FakeFS::Require.activate! opts
          FakeFS.activate!
        end
      end
      
      raise LoadError, "no such file to load -- " + orig_fn
    end
    
    module Autoload
      # Faked #autoload (see Module#autoload)
      def fakefs_autoload const, file
        Require.autoloadable[self] ||= {}
        Require.autoloadable[self][const] = file
      end
      
      # Faked #autoload? (see Module#autoload?)
      def fakefs_autoload? const
        hsh = Require.autoloadable[self]
        return hsh[const] if hsh
      end
      
      # Implementation of #const_missing, catches autoload cases
      def fakefs_const_missing name
        file = autoload? name
        if file
          require file
          return const_get name if const_defined? name
        end
        parent = (self == Object) ? "" : self.to_s + "::"
        raise NameError, "uninitialized constant #{parent + name.to_s}", caller
      end
    end
    
    module Load
      # Faked #load (see Kernel#load)
      def fakefs_load fn, wrap = false
        fn = fn.to_s
        orig_fn = fn.dup
        
        path = FakeFS::Require.resolve fn
        
        if path
          File.open path, "r" do |f|
            if wrap
              Module.new.module_eval f.read, fn, 1
            else
              Object.class_eval f.read, fn, 1
            end
          end
          return true
        elsif FakeFS::Require.opts[:fallback]
          return fakefs_original_load orig_fn, wrap
        end
        
        raise LoadError, "no such file to load -- " + fn
      end
    end
    
  end
  
end

module Kernel
  include FakeFS::Require
  include FakeFS::Require::Load
end

class Module
  include FakeFS::Require::Autoload
end
