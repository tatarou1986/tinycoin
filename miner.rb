# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'digest/sha2'

module Tinycoin
  class Miner
    attr_reader :blockchain
    attr_reader :genesis

    def initialize genesis, blockchain, tx_store, wallet
      @genesis    = genesis
      @blockchain = blockchain
      @tx_store    = tx_store
      @wallet     = wallet
      @cancel     = false
      @mining_wait_time = 0
    end

    def log
      @log ||= Tinycoin::Logger.create("miner")
      @log
    end

    # 乱数時間だけ待たせる
    def choke! cancel = false
      if cancel
        @mining_wait_time = 0
      else
        @mining_wait_time = rand(0.5)
      end
      @mining_wait_time
    end

    def cancel!
      @canceled = true
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

      prev_hash        = @blockchain.winner_block_head.to_sha256hash_s
      prev_height      = @blockchain.winner_block_head.height

      ## tx_outからtxを作る機構がいる
      ## txs = [Tinycoin::Core::TxBuilder.make_coinbase(@wallet)]
      newblock = Tinycoin::Core::BlockBuilder.make_block_as_miner(
             wallet      = @wallet,
             prev_hash   = prev_hash,
             nonce       = nonce,
             bits        = bits,
             ittime      = inttime,
             prev_height = prev_height + 1
      )
      @canceled = false
      @mining_wait_time = 0
      
      until found || @canceled
        newblock.nonce = nonce
        h = Digest::SHA256.hexdigest(Digest::SHA256.digest(newblock.to_binary_s)).to_i(16)
        if h <= t
          found = [h.to_s(16).rjust(64, '0'), nonce]
          begin
            log.info {
              "\e[33m Mining success! (nonce: #{found[1]})\e[0m" +
              "Try to append block(#{newblock.height}, #{newblock.to_sha256hash_s})"
            }
            @blockchain.maybe_append_block(prev_hash, newblock, true)
            log.info {
              "\e[32m Block(#{newblock.height}, #{newblock.to_sha256hash_s}" +
              " additional success \e[0m)"
            }
            # 採掘に成功したので、検証と、uxtoのストアに保存する
            Tinycoin::Core::TxValidator.validate_and_store_uxto(newblock.txs, @tx_store)
          rescue Tinycoin::Errors::NoAvailableBlockFound => e
            log.debug {
              "\e[31m Failed to append new block(#{newblock.to_sha256hash_s})." +
              "\e[0m No such prev_block(#{prev_height}, #{prev_hash}). " + 
              "initialize miner and then restart"
            }
          rescue Tinycoin::Errors::InvalidBlock => e
            # 自分が採掘したブロックなのにinvalidなのは明らかにおかしい。バグ
            log.fatal { "\e[31m Failed to append new block(#{newblock.to_sha256hash_s}). Invalid block" }
            log.fatal { "dump block: #{newblock.to_json}"}
            exit(-1)
          rescue Tinycoin::Errors::InvalidTx => e
            # 自分が採掘したブロックなのにinvalidなのは明らかにおかしい。バグ
            log.fatal { "\e[31m Failed to append new block(#{newblock.to_sha256hash_s}). Invalid Tx" }
            log.fatal { "dump block: #{newblock.to_json}"}
            exit(-1)
          rescue Tinycoin::Errors::ChainBranchingDetected => e
            log.debug { 
              "\e[31m Failed to append new block(#{newblock.to_sha256hash_s}). \e[0m" + 
              "The blockchain branching has been detected. maybe we lose this mining turn (height: #{newblock.height})" + 
              "Initialize miner and then restart with a new height (#{newblock.height + 1})\n" 
            }
          rescue => e
            # block追加が失敗。マイナーを初期化して、次のブロック採掘に向かう
            log.error { "#{e}: \e[31m Failed to append new block(#{newblock.to_sha256hash_s})" +
              " \e[0m due to unknown error\n #{e.backtrace.join("\n")}" }
            break
          end
          break
        end

        if @mining_wait_time > 0.0
          sleep @mining_wait_time
        end
        nonce += 1
      end

      if @canceled
        return nil
      else
        return found
      end
    end

    def self.do_genesis_mining log
      target = Tinycoin::Core::BlockChain.get_target(Tinycoin::Core::GENESIS_BITS).first
      
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
        d = Tinycoin::Core::Block.new_block(
                 prev_hash = "0000000000000000000000000000000000000000000000000000000000000000",
                 nonce = nonce,
                 bits = Tinycoin::Core::GENESIS_BITS,
                 time = inttime,                                           
                 height = 0,
                 payloadstr = "",
        )
        h = Digest::SHA256.hexdigest(Digest::SHA256.digest(d.to_binary_s)).to_i(16)
        
        if h <= t
          found = [h.to_s(16).rjust(64, '0'), nonce]
          break
        end
        nonce += 1
      end
      log.info { "genesis hash: time: #{inttime}, #{found[0]}, nonce: #{found[1]}" }
    end


    def self.do_mining_with_txs log, wallet, prev_hash, bits, time, height, txs, payloadstr = ""
      target = Tinycoin::Core::BlockChain.get_target(Tinycoin::Core::GENESIS_BITS).first
      log.info { "target: " + target }

      found = nil
      nonce = 0
      t = target.to_i(16)

      log.info { "mining genesis hash time: #{time} (unixtime: #{time.to_i})" }
      inttime = time.to_i
      d = nil

      until found
        log.info { sprintf("trying... %d \r", nonce) }
        #        $stdout.print sprintf("trying... %d \r", nonce)
        d = Tinycoin::Core::Block.new_block(
                prev_hash = prev_hash,
                nonce = nonce,
                bits = bits,
                time = inttime,
                height = height,
                payloadstr = payloadstr,
        )
        txs.each {|tx| d.add_tx(tx)}
        h = Digest::SHA256.hexdigest(Digest::SHA256.digest(d.to_binary_s)).to_i(16)

        if h <= t
          found = [h.to_s(16).rjust(64, '0'), nonce]
          break
        end
        nonce += 1
      end
      log.info {  d.to_json }
    end
    
  end
end
