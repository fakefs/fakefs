# frozen_string_literal: true

module FakeFS
  # Version module
  module Version
    VERSION = '3.2.1'

    def self.to_s
      VERSION
    end
  end
end
