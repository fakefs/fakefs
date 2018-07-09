module FakeFS
  # Version module
  module Version
    VERSION = '0.15.0'.freeze

    def self.to_s
      VERSION
    end
  end
end
