# frozen_string_literal: true

module FakeFS
  # Kernel Module
  module Kernel
    @captives = { original: {}, hijacked: {} }

    class << self
      attr_accessor :captives
    end

    def self.hijack!
      captives[:hijacked].each do |name, prc|
        ::Kernel.send(:remove_method, name.to_sym)
        ::Kernel.send(:define_method, name.to_sym, &prc)
        ::Kernel.send(:private, name.to_sym)
      end
    end

    def self.unhijack!
      captives[:original].each_key do |name|
        ::Kernel.send(:remove_method, name.to_sym)
        ::Kernel.send(:define_method, name.to_sym, proc do |*args, **kwargs, &block|
          ::FakeFS::Kernel.captives[:original][name].call(*args, **kwargs, &block)
        end)
        ::Kernel.send(:private, name.to_sym)
      end
    end

    # NOTE: maybe private
    def self.hijack(name, &block)
      captives[:original][name] = ::Kernel.method(name.to_sym)
      captives[:hijacked][name] = block || proc { |_args| }
    end

    hijack :open do |*args, &block|
      # This is a system command     or   we're inside IRB internals
      if args.first.start_with?('|') || self.class.to_s.start_with?("IRB::")
        ::FakeFS::Kernel.captives[:original][:open].call(*args, &block)
      else
        name = args.shift
        FakeFS::File.open(name, *args, &block)
      end
    end
  end
end
