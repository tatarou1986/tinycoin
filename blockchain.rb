# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'digest/sha2'
require 'json'

module Tinycoin::Core
  autoload :Block, "./block.rb"

  # ブロック作成用
  autoload :BlockBuilder, "./block_builder.rb"

  # トランザクション自体を表すクラス
  autoload :Tx, "./tx.rb"
  autoload :TxIn, "./tx_in.rb"
  autoload :TxOut, "./tx_out.rb"
  autoload :UXTOStore, "./tx_store.rb"

  # トランザクション作成器
  autoload :TxBuilder, "./tx_builder.rb"

  # トランザクションの検証器
  autoload :TxValidator, "./tx_validator.rb"

  # ウォレット（財布）の管理
  autoload :Wallet, "./wallet.rb"

  # ブロックチェーン上に乗るScriptの実装
  autoload :Script, "./script.rb"
  
  # 仮想マシン
  autoload :VM, "./vm.rb"
  
  MINING_EVENT_INTERVAL = 0
  POW_LIMIT = "00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  POW_TARGET_TIMESPAN = 14 * 24 * 60 * 60 ## two weeks sec
  POW_DIFFICULTY_BLOCKSPAN = 2016 # blocks
  # POW_TARGET_TIMESPAN = 120 ## two weeks sec
  # POW_DIFFICULTY_BLOCKSPAN = 2 # blocks

  ## target: 0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
  ## mining genesis hash time: 2018-05-05 23:52:35 (unixtime: 1525531912)
  ## genesis hash: 0000d739b4627badcfa12f9d9976554d0c0e9f7a8106f53d8d1b4920a0300ab4, nonce: 90605
  GENESIS_HASH  = "0000d739b4627badcfa12f9d9976554d0c0e9f7a8106f53d8d1b4920a0300ab4"
  GENESIS_NONCE = 90605
  GENESIS_BITS  = 0x1effffff
  GENESIS_TIME  = 1525531912

  MINER_REWARD_AMOUNT = 1

  class BlockChain
    attr_reader :head_info_array
    attr_reader :winner_block_head
    
    def initialize genesis_block, front = nil
      @root = genesis_block                         # 創始 (genesis) ブロック
      @winner_block_head = genesis_block            # blockchainの一番新しいブロック
      @head_info_array = [@root, 0, 0, @root.bits]  # [ブロック, height, difficulty再設定後からカウントしたheight, 現在の難易度]
      @block_append_lock = Mutex.new
      @front = front
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
      # block.each {|tx|
      #   # txはここでシリアライズすべき？
      #   # 多分まだ
      # }
      log.warn { "not implemented" }
      true
    end

    # blockに含まれる difficulty (採掘難易度) が正しいかどうか検証を行う
    def validate_block_diffictuly block
      log.warn { "not implemented" }
      true
    end

    # def maybe_append_block_from_hash new_block_hash
    #   @block_append_lock.synchronize {
    #     block = Tinycoin::Core::Block.new_block_from_hash(new_block_hash, true)

    #     # TODO: トランザクションの検証
    #     validate_block_txs(block)
        
    #     # TODO: diffictulyの検証
    #     validate_block_diffictuly(block)
    #   }
    # end

    # ブロックの追加を試す
    # TODO: リファクタリング。名前を変える
    def maybe_append_block_from_json new_block_json
      @block_append_lock.synchronize {
        begin
          prev_hash = @winner_block_head.to_sha256hash_s
          ok = Tinycoin::Core::Block.validate_block_json(new_block_json, Tinycoin::Core::GENESIS_BITS)

          # 検証と、uxtoのストアに保存する
          ret = Tinycoin::Core::TxValidator.validate_and_store_uxto(ok.txs, @front.tx_store)

          if ret
            add_block(prev_hash, ok)
          end
        rescue => e
          log.error { "#{e}: \e[31m Failed to append new block(#{ok.to_sha256hash_s}) \e[0m due to unknown error\n #{e.backtrace.join("\n")}" }
        end
      }
    end

    # TODO: リファクタリング。名前を変える
    def maybe_append_block prev_hash, newblock, from_miner = false
      @block_append_lock.synchronize {
        # 一度jsonに変換してからvalidateする。無駄だが今はとりあえずこうする
        begin 
          ok = Tinycoin::Core::Block.validate_block_json(newblock.to_json, Tinycoin::Core::GENESIS_BITS)
          
          # 採掘に成功したので、検証と、uxtoのストアに保存する
          ret = Tinycoin::Core::TxValidator.validate_and_store_uxto(ok.txs, @front.tx_store)
          if ret
            add_block(prev_hash, ok, from_miner)
          end
        rescue => e
          log.error { "#{e}: \e[31m Failed to append new block(#{ok.to_sha256hash_s}) \e[0m due to unknown error\n #{e.backtrace.join("\n")}" }
        end
      }
    end

    # blockを追加する。(miner) 自分が採掘したblockを追加する場合か
    # 他のノードからのブロック追加なのかでblock追加成功条件が変わる
    def add_block prev_hash, newblock, from_miner = false
      block = find_block_by_hash(prev_hash)
      
      raise Tinycoin::Errors::NoAvailableBlockFound if block == nil
      
      # miner (自分が採掘したblock) からのblock追加の場合
      # 自分から積極的にblockchainの分岐に加担するべきではないので
      # 分岐してしまう場合は、ブロック追加しない
      # ...と思っていたが、上のアルゴリズムだと、ノード全員が分岐していた場合、
      # どのノードもブロックを追加しなくなって、誰もブロックをマイニングせずに
      # 結果、全ノードデッドロックするので、ブランチを検出した場合、マイナーからの追加は行わない
      # という戦略はまずい。最適な戦略は、自分のマイナーにたいして、乱数で
      # 待ち時間を追加して、各ノードのマイニング速度を調整して、誰かが勝つように促すしかない
      if block.next.size >= 1

        # すでに同一ブロックが存在する場合は追加しない
        if block.next.detect {|b| b.to_sha256hash_s == newblock.to_sha256hash_s }
          log.info { "\e[31m blockchain has already same block(#{newblock.height}, #{newblock.to_sha256hash_s}). Cancel to append the block \e[0m" }
          find_winner_block_head(true) # bestBlockが更新されたかもしれないのでチェックする
          return newblock
        end
        
        if @front
          choke_time = @front.miner.choke!
          log.info { "\e[31m blockchain has been branched. execute choking to my miner(#{choke_time}) \e[0m" }
        else
          log.warn { "\e[31m blockchain has been branched but does not execute choking due to front is null \e[0m" }
        end
      end

      block.next << newblock
      find_winner_block_head(true) # bestBlockが更新されたかもしれないのでチェックする
      return newblock
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
            deepest_block_difficulty = diff
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

