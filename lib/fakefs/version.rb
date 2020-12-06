module FakeFS
  # Version module
  module Version
    VERSION = '1.2.3'.freeze

    def self.to_s
      VERSION
    end
  end
end
