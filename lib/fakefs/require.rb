module FakeFS
  class Require
    @options = [{
      :require => true,
      :load => true,
      :autoload => false,
      :fallback => false
    }]
    
    def self.require(filename, &fallback)
      filename = String(filename)
      orig_fn = filename.dup
      
      filename = filename + ".rb" unless filename[-3..-1] == ".rb"
      path = resolve(filename)
      
      if path
        return false if $LOADED_FEATURES.include? path
        
        File.open(path, "r") {|f|
          Object.class_eval f.read, path, 1
        }
        $LOADED_FEATURES << path
        return true
      elsif options[:fallback]
        return fallback.call
      end
      
      raise LoadError, "no such file to load -- #{orig_fn} (fakefs)"
    end
    
    def self.load(filename, wrap, &fallback)
      filename = String(filename)
      orig_fn = filename.dup
      
      path = resolve(filename)
      
      if path
        File.open(path, "r") {|f|
          if wrap
            Module.new.module_eval f.read, path, 1
          else
            Object.class_eval f.read, path, 1
          end
        }
        return true
      elsif options[:fallback]
        return fallback.call
      end
      
      raise LoadError, "no such file to load -- #{orig_fn} (fakefs)"
    end
    
    @autoload_data = [Hash.new {|h, k| h[k] = {} }]
    
    def self.autoload(object, constant_name, filename)
      autoload_data[object][constant_name.to_sym] = filename
    end
    
    def self.autoload?(object, constant_name, &fallback)
      filename = autoload_data[object][constant_name.to_sym]
      if options[:fallback]
        filename ||= fallback.call
      end
      filename
    end
    
    def self.constant_missing(object, constant_name)
      if filename = object.autoload?(constant_name)
        require filename
        if object.const_defined? constant_name
          return object.const_get constant_name
        end
      end
      
      name = "#{object}::#{constant_name}"
      raise NameError, "uninitialized constant #{name}", caller
    end
    
    def self.resolve(filename)
      found = nil
      if filename[0...1] == "/"
        found = filename if File.exist? filename
      else
        $LOAD_PATH.each do |p|
          path = p + "/" + filename
          if File.exist? path
            found = File.expand_path(path)
            break
          end
        end
      end
      
      found
    end
    
    def self.options
      active? ? @options.last : {}
    end
    
    def self.active?
      !!@active
    end
    
    def self.autoload_data
      active? ? @autoload_data.last : {}
    end
    
    def self.activate!(opts = {})
      @active = true
      @options << @options.last.merge(opts)
      @autoload_data << @autoload_data.last.dup
    end
    
    def self.deactivate!
      return unless active?
      @options.pop
      @autoload_data.pop
      @active = false if @options.size == 1
    end
  end
end
  
module Kernel
  alias_method :fakefs_original_require, :require
  alias_method :fakefs_original_load, :load
  
  def require(filename)
    if FakeFS::Require.options[:require]
      FakeFS::Require.require(filename) {
        fakefs_original_require filename
      }
    else
      fakefs_original_require filename
    end
  end
  
  def load(filename, wrap = false)
    if FakeFS::Require.options[:load]
      FakeFS::Require.load(filename, wrap) {
        fakefs_original_load filename, wrap
      }
    else
      fakefs_original_load filename, wrap
    end
  end
end

class Module
  alias_method :fakefs_original_autoload, :autoload
  alias_method :fakefs_original_autoload?, :autoload?
  alias_method :fakefs_original_const_missing, :const_missing
  
  def autoload(constant_name, filename)
    if FakeFS::Require.options[:autoload]
      FakeFS::Require.autoload self, constant_name, filename
    else
      fakefs_original_autoload constant_name, filename
    end
  end
  
  def autoload?(constant_name)
    if FakeFS::Require.options[:autoload]
      FakeFS::Require.autoload?(self, constant_name) {
        fakefs_original_autoload? constant_name
      }
    else
      fakefs_original_autoload? constant_name
    end
  end
  
  def const_missing(constant_name)
    if FakeFS::Require.options[:autoload]
      FakeFS::Require.constant_missing self, constant_name
    else
      fakefs_original_const_missing constant_name
    end
  end
end
