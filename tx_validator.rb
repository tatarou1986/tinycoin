module Tinycoin::Core
  class TxValidator
    attr_reader :in_tx
    attr_reader :out_tx
    attr_reader :signature

    def initialize
      @in_tx = "hello"
      @out_tx = "world"
      @out_tx = ""
    end
    
    def validate pubkey_hex, tx
    end
  end
end

