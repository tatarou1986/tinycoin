module Tinycoin::Core
  class TxBuilder
    def self.make_coinbase miner_pubkey_hex
      tx = Tx.new(miner_pubkey_hex, Tinycoin::Core::MINER_REWARD_AMOUNT)
      tx_in  = TxIn.new(coinbase = true)
      tx_out = TxOut.new(coinbase = true)

      tx.in_tx  = tx_in
      tx.in_out = tx_out
      
    end
  end
end
