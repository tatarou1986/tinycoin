# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'digest/sha2'

module Tinycoin
  class Miner
    attr_reader :blockchain
    attr_reader :genesis

    def initialize genesis, blockchain, tx_pool
      @genesis    = genesis
      @blockchain = blockchain
      @tx_pool    = tx_pool
    end

    def log
      @log ||= Tinycoin::Logger.create("miner")
      @log
    end

    def do_mining
      bits = @blockchain.head_info_array.last
      # TODO: payloadstrってのが要はblockに含めるtransactionである
      # payloadstrとtransactionの管理機構をどうするのかちゃんと考える必要がある
      # transactionPoolってのが必要で、そこからblockchainまだ記述されていないvalidなtransactionを得て
      # Blockを追加することになるだろう
      payloadstr = "" # @tx_pool.get_poolみたいな感じで
      target = Tinycoin::Core::BlockChain.get_target(bits).first

      log.info { "current target: #{target} (0x#{bits.to_s(16)})" }
      found  = nil
      nonce  = 0
      t = target.to_i(16)

      time = Time.now
      inttime = time.to_i
      
      until found
        prev_hash_binary = @blockchain.winner_block_head.to_sha256hash()
        prev_hash        = @blockchain.winner_block_head.to_sha256hash_s()
        prev_height      = @blockchain.winner_block_head.height

        d = Tinycoin::Types::BulkBlock.new(nonce: nonce, block_id: prev_height + 1,
                                           time: inttime, bits: bits,
                                           prev_hash: prev_hash_binary, strlen: 0, payloadstr: "")
        h = Digest::SHA256.hexdigest(Digest::SHA256.digest(d.to_binary_s)).to_i(16)
        
        if h <= t
          found = [h.to_s(16).rjust(64, '0'), nonce]         
          block = Tinycoin::Core::Block.new_block(prev_hash, nonce, bits, inttime, prev_height + 1, payloadstr)
          @blockchain.add_block(prev_hash, block)
          
          log.info { "found! hash: #{found[0]}, nonce: #{found[1]}" }
          break
        end
        nonce += 1
      end
      return found
    end

    def generate_genesis_block
      target = Tinycoin::Core::BlockChain.get_target(GENESIS_BITS).first
      
      log.info { "target: " + target }
      
      found = nil
      nonce = 0
      t = target.to_i(16)
      
      time = Time.now
      log.info { "mining genesis hash time: #{time} (unixtime: #{time.to_i})" }
      inttime = time.to_i
      
      until found
        log.info { sprintf("trying... %d \r", nonce) }
#        $stdout.print sprintf("trying... %d \r", nonce)
        d = Tinycoin::Types::BulkBlock.new(nonce: nonce, block_id: 0,
                                           time: inttime, bits: GENESIS_BITS,
                                           prev_hash: 0, strlen: 0, payloadstr: "")
        h = Digest::SHA256.hexdigest(Digest::SHA256.digest(d.to_binary_s)).to_i(16)

        if h <= t
          found = [h.to_s(16).rjust(64, '0'), nonce]
          break
        end
        nonce += 1
      end
      log.info { "genesis hash: #{found[0]}, nonce: #{found[1]}" }
    end
    
  end
end
