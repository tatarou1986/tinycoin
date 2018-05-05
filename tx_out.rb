# -*- coding: utf-8 -*-
module Tinycoin::Core
  class TxOut
    attr_reader :script_pubkey # 振出人の公開鍵と署名が含まれる
    attr_reader :address # 受取人アドレス (base58の文字列)
    attr_reader :amount
    
    def initialize
      @type = :unknown
    end

    def set_coinbase! wallet
      @type          = :coinbase
      @amount        = Tinycoin::Core::MINER_REWARD_AMOUNT
      @script_pubkey = Script.generate_coinbase_out
      @address       = wallet.address
    end

    def parse_from_hash hash
      begin
        @type          = :coinbase if hash.fetch("type") == "coinbase"
        @amount        = hash.fetch("value")
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

    def to_hash
      if @type == :coinbase
        {
          type: "coinbase",
          value: @amount.to_s.to_i(10),
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
          address: Wallet.decode_base58(@address).to_i(16)
      )
    end
  end
end
