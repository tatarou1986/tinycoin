# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'digest/sha2'

module Tinycoin
  class Miner
    attr_reader :blockchain
    attr_reader :genesis

    def initialize genesis, blockchain, tx_pool, wallet
      @genesis    = genesis
      @blockchain = blockchain
      @tx_pool    = tx_pool
      @wallet     = wallet
    end

    def log
      @log ||= Tinycoin::Logger.create("miner")
      @log
    end

    def do_mining
      bits = @blockchain.head_info_array.last
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
          block = Tinycoin::Core::BlockBuilder.make_block_as_miner(@wallet, prev_hash, nonce, bits, inttime, prev_height + 1)
          begin
            log.info { "\e[33m Mining success! (nonce: #{found[1]})\e[0m Try to append block(#{block.height}, #{block.to_sha256hash_s})" }
            @blockchain.maybe_append_block(prev_hash, block, true)
            log.info { "\e[32m Block(#{block.height}, #{block.to_sha256hash_s} additional success \e[0m)" }
          rescue Tinycoin::Errors::NoAvailableBlockFound => e
            log.debug { "\e[31m Failed to append new block(#{block.to_sha256hash_s}). \e[0m No such prev_block(#{prev_height}, #{prev_hash}). initialize miner and then restart" }
          rescue Tinycoin::Errors::ChainBranchingDetected => e
            log.debug { 
              "\e[31m Failed to append new block(#{block.to_sha256hash_s}). \e[0m" + 
              "The blockchain branching has been detected. maybe we lose this mining turn (height: #{block.height})" + 
              "Initialize miner and then restart with a new height (#{block.height + 1})\n" 
            }
          rescue => e
            # block追加が失敗。マイナーを初期化して、次のブロック採掘に向かう
            log.error { "m#{e}: \e[31m Failed to append new block(#{block.to_sha256hash_s}) \e[0m due to unknown error\n #{e.backtrace.join("\n")}" }
            break
          end
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
