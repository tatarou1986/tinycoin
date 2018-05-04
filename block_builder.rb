module Tinycoin::Core
  class BlockBuilder
    def self.make_block_as_miner wallet, prev_hash, nonce, bits, inttime, new_height
      payloadstr = ""
      new_block = Tinycoin::Core::Block.new_block(
          prev_hash,
          nonce,
          bits,
          inttime,
          new_height,
          payloadstr
      )

      new_tx = Tinycoin::Core::TxBuilder.make_coinbase(wallet)
      new_block.add_tx_as_first(new_tx)
      new_block
    end
  end
end
