module FakeFS
  module Kernel

    @captives = { :original => {}, :hijacked => {}}
    class << self
      attr_accessor :captives
    end

    def self.hijack!
      captives[:hijacked].each do |name,prc|
        ::Kernel.send(:define_method, name.to_sym, &prc)
      end
    end

    def self.unhijack!
      captives[:original].each do |name,prc|
        ::Kernel.send(:define_method, name.to_sym, Proc.new do |*args, &block|
          ::FakeFS::Kernel.captives[:original][name].call(*args, &block)
        end)
      end
    end

    private
    def self.hijack name, &block
      captives[:original][name] = ::Kernel.method(name.to_sym)
      captives[:hijacked][name] = block || Proc.new { |args| }
    end

    hijack :open do |*args, &block|
      if args.first.start_with? '|'
        # This is a system command
        ::FakeFS::Kernel.captives[:original][:open].call(*args, &block)
      else
        name, rest = *args
        FakeFS::File.open(name, *rest, &block)
      end
    end

  end
end
