module FakeFS
  # Version module
  module Version
    VERSION = '0.12.0'.freeze

    def self.to_s
      VERSION
    end
  end
end
