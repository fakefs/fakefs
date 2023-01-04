module FakeFS
  # Version module
  module Version
    VERSION = '2.0.0'.freeze

    def self.to_s
      VERSION
    end
  end
end
