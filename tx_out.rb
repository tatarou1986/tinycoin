# -*- coding: utf-8 -*-
module Tinycoin::Core
  class TxOut
    attr_reader :script_pubkey # 振出人の公開鍵と署名が含まれる
    attr_reader :address # 受取人アドレス (base58の文字列)
    attr_reader :amount
    attr_reader :locktime
    
    def initialize
      @type = :unknown
    end

    def set_coinbase! wallet
      @type          = :coinbase
      @amount        = Tinycoin::Core::MINER_REWARD_AMOUNT
      @script_pubkey = Script.generate_coinbase_out
      @address       = wallet.address
      @locktime      = Time.now.to_i
    end

    def parse_from_hash hash
      begin
        @type          = :coinbase if hash.fetch("type") == "coinbase"
        @amount        = hash.fetch("value")
        @locktime      = hash.fetch("locktime")
        @script_pubkey = hash.fetch("scriptPubKey").fetch("asm")
        @address       = hash.fetch("scriptPubKey").fetch("address")
        self
      rescue KeyError
        raise Tinycoin::Errors::InvalidFieldFormat
      end
    end

    def to_binary_s
      generate_blk.to_binary_s
    end

    def to_json
      to_hash.to_json
    end

    def to_binary_s
      generate_blk.to_binary_s
    end

    def to_sha256hash_s
      to_sha256hash.to_s(16).rjust(64, '0')
    end

    def to_sha256hash
      blk_tx = generate_blk
      @tx_id = Digest::SHA256.hexdigest(Digest::SHA256.digest(blk_tx.to_binary_s)).to_i(16)
      @tx_id
    end

    def to_hash
      if @type == :coinbase
        {
          type: "coinbase",
          hash: to_sha256hash_s,
          value: @amount.to_s.to_i(10),
          locktime: @locktime,
          scriptPubKey: {
            asm: @script_pubkey.to_s,
            address: @address.to_s
          }
        }
      else
        raise Tinycoin::Errors::NotImplemented
        {
          type: "unknown"
        }
      end
    end
    
    def generate_blk
      Tinycoin::Types::BulkTxOut.new(
          amount: @amount,
          script_len: @script_pubkey.to_s.size,
          script_pubkey: @script_pubkey.to_s,
          locktime: @locktime,                                    
          address: Wallet.decode_base58(@address).to_i(16)
      )
    end
  end
end
