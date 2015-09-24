module Kernel
  def eigenclass
    class << self
      self
    end
  end
end

module FakeFS
  # Kernel Module
  module Kernel
    @captives = { original: {}, hijacked: {} }

    class << self
      attr_accessor :captives
    end

    def self.hijack!
      captives[:hijacked].each do |name, prc|
        name = name.to_sym
         ::Kernel.class_eval do
           private
           alias_method(:"#{name}_original", name)
           eigenclass.send(:alias_method, :"#{name}_original", name)

           define_method(name, &prc)
           module_function(name)
         end
      end
    end

    def self.unhijack!
      captives[:original].each do |name, _prc|
         ::Kernel.class_eval do
           if method_defined?(:"#{name}_original")
             alias_method(name, :"#{name}_original")
             eigenclass.alias_method(name, :"#{name}_original")
           end
         end
      end
    end

    private

    def self.hijack(name, &block)
      captives[:original][name] = ::Kernel.method(name.to_sym)
      captives[:hijacked][name] = block || proc { |_args| }
    end

    hijack :open do |name, *args, &block|
      if name.start_with?('|') ||
          (name.respond_to?(:to_str) && %r{\A[A-Za-z][A-Za-z0-9+\-\.]*://} =~ name)
        # This is a system command
        ::FakeFS::Kernel.captives[:original][:open].call(name, *args, &block)
      else
        FakeFS::File.open(name, *args, &block)
      end
    end
  end
end
