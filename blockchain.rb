# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'digest/sha2'
require 'json'

module Tinycoin::Core
  autoload :Block, "./block.rb"

  # トランザクション自体を表すクラス
  autoload :Tx, "./tx.rb"

  # トランザクションの検証器
  autoload :TxValidator, "./tx.rb"

  # ウォレット（財布）の管理
  autoload :Wallet, "./wallet.rb"
  
  MINING_EVENT_INTERVAL = 0
  POW_LIMIT = "00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  POW_TARGET_TIMESPAN = 14 * 24 * 60 * 60 ## two weeks sec
  POW_DIFFICULTY_BLOCKSPAN = 2016 # blocks
  # POW_TARGET_TIMESPAN = 120 ## two weeks sec
  # POW_DIFFICULTY_BLOCKSPAN = 2 # blocks

  ## target: 0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
  ## mining genesis hash time: 2016-04-19 09:19:36 +0900 (unixtime: 1461025176)
  ## genesis hash: 0000610c19db37b3352ef55d87bc22426c8fa0a7333e08658b4a7a9b95bc54cf, nonce: 8826
  GENESIS_HASH  = "0000610c19db37b3352ef55d87bc22426c8fa0a7333e08658b4a7a9b95bc54cf"
  GENESIS_NONCE = 8826
  GENESIS_BITS  = 0x1effffff
  GENESIS_TIME  = 1461025176

  class BlockChain
    attr_reader :head_info_array
    attr_reader :winner_block_head
    
    def initialize genesis_block
      @root = genesis_block                         # 創始 (genesis) ブロック
      @winner_block_head = genesis_block            # blockchainの一番新しいブロック
      @head_info_array = [@root, 0, 0, @root.bits]  # [ブロック, height, difficulty再設定後からカウントしたheight, 現在の難易度]
      @block_append_lock = Mutex.new
    end

    def log
      @log ||= Tinycoin::Logger.create("blockchain")
      @log
    end

    # TOOD: lockを取らないとダメ!
    def best_block; @block_append_lock.synchronize { @winner_block_head }; end
    def current_difficulty; @block_append_lock.synchronize { @head_info_array[3] }; end
    
    # blockに含まれるトランザクションが正しいかどうか検証を行う
    def validate_block_txs block
      log.warn { "not implemented" }
      true
    end

    # blockに含まれる difficulty (採掘難易度) が正しいかどうか検証を行う
    def validate_block_diffictuly block
      log.warn { "not implemented" }
      true
    end

    def maybe_append_block_from_hash new_block_hash
      @block_append_lock.synchronize {
        block = Tinycoin::Core::Block.new_block_from_hash(new_block_hash, true)

        # TODO: トランザクションの検証
        validate_block_txs(block)
        
        # TODO: diffictulyの検証
        validate_block_diffictuly(block)
      }
    end

    # ブロックの追加を試す
    # TODO: 要テスト
    def maybe_append_block_from_json new_block_json
      @block_append_lock.synchronize {
        block = Tinycoin::Core::Block.parse_json(new_block_json, true)

        # TODO: トランザクションの検証
        validate_block_txs(block)
        
        # TODO: diffictulyの検証
        validate_block_diffictuly(block)
      }
    end

    def maybe_append_block prev_hash, newblock, from_miner = false
      @block_append_lock.synchronize { add_block(prev_hash, newblock, from_miner) }
    end

    # blockを追加する。(miner) 自分が採掘したblockを追加する場合か
    # 他のノードからのブロック追加なのかでblock追加成功条件が変わる
    def add_block prev_hash, newblock, from_miner = false
      block = find_block_by_hash(prev_hash)
      
      raise Tinycoin::Errors::NoAvailableBlockFound if block == nil
      
      # miner (自分が採掘したblock) からのblock追加の場合
      # 自分から積極的にblockchainの分岐に加担するべきではないので
      # 分岐してしまう場合は、ブロック追加しない
      if from_miner
        if block.next.size == 0
          block.next << newblock
          find_winner_block_head(true) # bestBlockが更新されたかもしれないのでチェックする
          return newblock
        else
          raise Tinycoin::Errors::ChainBranchingDetected
        end
      else
        # minerからのブロック追加ではない場合（他ノードからのブロック追加）は
        # 自分が無知なだけで、自分よりはるかに高いheightを持っているノードがいるかも知れないので
        # 分岐するのはやむなしとして追加する
        block.next << newblock
        
        find_winner_block_head(true) # bestBlockが更新されたかもしれないのでチェックする
        return newblock
      end
    end

    def find_winner_block_head(refresh = false)
      if refresh
        @winner_block_head = nil
        @head_info_array = nil
      end
      @head_info_array ||= do_find_winner_block_head(@root, 0, 0, GENESIS_BITS, GENESIS_TIME)
      @winner_block_head ||= @head_info_array.first

      return @winner_block_head
    end
    
    def do_find_winner_block_head(block, depth, cumulative_depth, difficulty, latest_time)
      return [block, depth, cumulative_depth, difficulty] if block.next.size == 0      
      depth += 1
      
      if cumulative_depth > POW_DIFFICULTY_BLOCKSPAN
        cumulative_depth = 0
        time = Time.at(block.time).tv_sec - Time.at(latest_time).tv_sec
        difficulty = BlockChain.block_new_difficulty(difficulty, time)
        puts "difficulty changed -> time: #{time} bits: #{difficulty}"
        latest_time = block.time
      else
        cumulative_depth += 1
      end
      
      if block.next.size > 1
        ## has branch
        current_depth = 1
        current_cdp = cumulative_depth
        deepest_block = block.next.first
        deepest_block_difficulty = difficulty

        ## find a winner block
        block.next.each{|b|
          bl, dp, cdp, diff = do_find_winner_block_head(b, 0, 0, difficulty, latest_time)
          if dp > current_depth then
            deepest_block = bl
            current_depth = dp
            current_cdp   = cdp
            deppest_block_difficulty = diff
          end
        }

        return [ deepest_block, 
                (depth + current_depth), 
                (cumulative_depth + current_cdp), 
                deepest_block_difficulty ]
      else        
        ## has no branch
        return do_find_winner_block_head(block.next.first, depth,
                                         cumulative_depth, difficulty, latest_time)
      end
    end

    def find_block_by_height(height)
      do_find_block_by_height(@root, height)
    end

    def do_find_block_by_height(block, height)
      return [block] if block.height == height

      if block.next.size == 1 # このブロック
        return do_find_block_by_height(block.next.first, height)
      elsif block.next.size > 1
        # ブロックが分岐している時は同一heightのBlockが複数あるので先にチェック
        return block.next if block.next.first.height == height
        block.next.each{|b|
          tmp = do_find_block_by_height(b, height)
          return tmp if tmp != nil # 見つかった!
        }
        return nil
      else
        return nil
      end
    end
    
    def find_block_by_hash(hash_str)
      do_find_block_by_hash(@root, hash_str)
    end

    def do_find_block_by_hash(block, hash_str)
      return block if block.to_sha256hash_s == hash_str
      return nil if block.next.size == 0

      block.next.each{|b|
        tmp = do_find_block_by_hash(b, hash_str)
        if tmp != nil
          ##
          ## found it
          ##
          return tmp
        end
      }

      return nil
    end

    ##
    ## time_of_lastblocks: uint64_t
    ##
    def self.block_new_difficulty(old_difficulty, time_of_lastblocks)
      new_difficulty = old_difficulty * (time_of_lastblocks.to_f / POW_TARGET_TIMESPAN)
      return new_difficulty.to_i
    end

    def self.get_target(bits)
      coefficient = bits & 0xffffff
      exponent    = (bits >> 24) & 0xff

      target     = coefficient * (2 ** (8 * (exponent - 3)))
      str        = target.to_s(16).rjust(64, '0')
      target_str = ""
      str.reverse!
      
      first_hex = nil
      str.each_char{|c|
        if first_hex == nil && c != '0'
          first_hex = true
        end

        if first_hex && c == '0'
          break
        end
        
        target_str << 'f'
      }

      return [target_str.rjust(64, '0'), target]
    end
  end
end

