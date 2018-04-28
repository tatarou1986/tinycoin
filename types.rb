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

  class BulkTx < BinData::Record
    endian :little
    uint32 :signer_pubkey_size, :value => lambda { signer_pubkey.length }
    array  :signer_pubkey, :type => :uint8
    uint32 :signature_size, :value => lambda { signature.length }
    array  :signature, :type => :uint8
    uint64 :amount
  end
end
