module Tinycoin::Types
  class BulkTx < BinData::Record
    endian :little
  end
  
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
end
