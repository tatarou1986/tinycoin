# -*- coding: utf-8 -*-
require 'json'

module Tinycoin::Core
  class TxOut
    attr_reader :script_pubkey # 振出人の公開鍵と署名が含まれる
    attr_reader :address # 受取人アドレス
    attr_reader :amount
    
    def initialize coinbase = false
      if coinbase
        @type          = :coinbase
        @amount        = Tinycoin::Core::MINER_REWARD_AMOUNT
        @script_pubkey = Script.generate_coinbase_out
      else
        raise Tinycoin::Errors::NotImplemented
      end
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      if @type == :coinbase
        {
          type: "coinbase",
          value: @amount.to_s.to_i(10),
          scriptSig: {
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
  end
end
