module Tinycoin::Core
  class TxIn
    attr_reader :type
    attr_reader :script_sig
    
    def initialize(coinbase = false)
      if coinbase
        @type       = :coinbase
        @script_sig = Script.generate_coinbase_in
      end
    end

    def parse_from_hash hash
      begin
        @type       = :coinbase if hash.fetch("type") == "coinbase"
        @script_sig = hash.fetch("scriptSig").fetch("asm")
        self
      rescue KeyError
        raise Tinycoin::Errors::InvalidFieldFormat
      end
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      if @type == :coinbase
        {
          type: "coinbase",
          scriptSig: {
            asm: @script_sig.to_s
          }
        }
      else
        {
          type: "unknown"
        }
      end
    end
  end
end
