module Tinycoin::Core
  class TxBuilder
    def self.make_coinbase miner_wallet
      tx = Tx.new
      tx_in  = TxIn.new(coinbase = true)
      tx_out = TxOut.new(coinbase = true)

      tx.set_in(tx_in)
      tx.set_out(tx_out)

      tx
    end
  end
end
