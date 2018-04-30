module Tinycoin::Core
  class TxIn
    attr_reader :type
    
    def initialize(coinbase = false)
      if coinbase
        @type = :coinbase
      end
    end

    def coinbase?
      if @coinbase
        true
      else
        false
      end
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      if @coinbase
        {type: "coinbase"}
      else
        {type: "unknown"}
      end
    end
  end
end
