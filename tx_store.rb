# -*- coding: utf-8 -*-
module Tinycoin::Core
  class TxStore
    def initialize
      # valid済みのtx
      @uxto_store = {}

      # validじゃないtx
      @orphans_store = {}

      # address -> uxtoのkey-value
      @address_to_uxto = {}

      @store_lock = Mutex.new
    end

    # +tx_hash+ 検索対象のtxハッシュを文字列で
    def get_uxto_by_hash tx_hash
      @store_lock.synchronize {
        begin
          @uxto_store.fetch(tx_hash)
       rescue KeyError
          raise Tinycoin::Errors::NoSuchTx
        end
      }
    end

    def get_uxto_by_address base58_str, pay_out = false
      @store_lock.synchronize {
        begin
          if pay_out
            uxto = @address_to_uxto.fetch(base58_str)
            @uxto_store.fetch(uxto.to_sha256hash_s)
            uxto
          else
            uxto = @address_to_uxto.fetch(base58_str)
            uxto
          end
        rescue KeyError
          raise Tinycoin::Errors::NoSuchTx
        end
      }
    end

    def all_uxto_json
      @store_lock.synchronize {
        @uxto_store.values.map {|v| v.to_json}.to_json
      }
    end
    
    # +tx_hash+ 検索対象のtxハッシュを文字列で
    def get_orphan_tx_by_hash tx_hash
      @store_lock.synchronize {
      }
    end

    # +tx_hash+ txのハッシュをstrで
    # +tx_out+ TxOutを入れる
    def put_uxto tx_hash, tx_out
      @store_lock.synchronize {
        @uxto_store[tx_hash] = tx_out

        # wallet address -> tx_outの列も使う
        uxtos = @address_to_uxto[tx_out.address]
        if uxtos          
          uxtos << tx_out
        else
          uxtos = []
          uxtos << tx_out
        end
        @address_to_uxto[tx_out.address] = uxtos
      }
    end

    def put_orphan tx_hash, tx_out
      @store_lock.synchronize {
        @orphans_store[tx_hash] = tx_out
      }
    end
  end
end
