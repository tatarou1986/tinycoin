# -*- coding: utf-8 -*-

module Tinycoin::Types
  # class BulkTx < BinData::Record
  #   endian :little
  # end
  
  class BulkBlock < BinData::Record
    endian :little
    uint64 :block_id
    uint64 :time
    uint64 :bits
    bit256 :prev_hash
    uint32 :strlen
    string :payloadstr, :read_length => :strlen
    uint64 :nonce
  end

  class BulkTxIn < BinData::Record
    endian :little
    uint32 :script_len
    string :script_pubkey, :read_length => :script_len
  end

  class BulkTxOut < BinData::Record
    endian :little
    uint64 :amount
    uint32 :script_len
    string :script_pubkey, :read_length => :script_len
    bit160 :address # 払い出し先のアドレス
  end

  class BulkTx < BinData::Record
    endian       :little
    bit256       :tx_id
    bulk_tx_out  :tx_out
    bulk_tx_in   :tx_in
  end
end
