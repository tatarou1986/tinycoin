module Tinycoin::Core
  class Script
    def self.generate_coinbase_out
      "OP_PUSH true"
    end

    def self.generate_coinbase_in
      "OP_NOP"
    end

    def self.parse str
      str.to_s.gsub(/\s+/m, ' ').strip.split(" ")
    end
  end
end
