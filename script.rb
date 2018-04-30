module Tinycoin::Core
  class Script
    def self.generate_coinbase
      "OP_PUSH true"
    end

    def self.parse str
      str.to_s.gsub(/\s+/m, ' ').strip.split(" ")
    end
  end
end
