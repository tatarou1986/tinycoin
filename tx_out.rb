module Tinycoin::Core
  class TxOut
    
    def initialize coinbase = false
      @coinbase = coinbase
      if coinbase
      end
    end

    def coinbase?; !!@coinbase; end
  end
end
