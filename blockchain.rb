require 'bundler/setup'
Bundler.require

require 'digest/sha2'
require 'json'

module Tinycoin::Core
  MINING_EVENT_INTERVAL = 0
  POW_LIMIT = "00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  POW_TARGET_TIMESPAN = 14 * 24 * 60 * 60 ## two weeks sec
  POW_DIFFICULTY_BLOCKSPAN = 2016 # blocks

  ## target: 0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
  ## mining genesis hash time: 2016-04-19 09:19:36 +0900 (unixtime: 1461025176)
  ## genesis hash: 0000610c19db37b3352ef55d87bc22426c8fa0a7333e08658b4a7a9b95bc54cf, nonce: 8826
  GENESIS_HASH  = "0000610c19db37b3352ef55d87bc22426c8fa0a7333e08658b4a7a9b95bc54cf"
  GENESIS_NONCE = 8826
  GENESIS_BITS  = 0x1effffff
  GENESIS_TIME  = 1461025176

  class BlockChain
    attr_reader :root
    attr_accessor :winner_block_head
    attr_accessor :head_info_array

    def initialize genesis_block
      @root = genesis_block
      @winner_block_head = genesis_block
      @head_info_array = [@root, 0, 0, @root.bits]
    end

    def add_block(prev_hash, newblock)
      block = find_block_by_hash(prev_hash)
      
      raise Tinycoin::Errors::NoAvailableBlockFound if block == nil
      block.next << newblock
      
      find_winner_block_head(true)
      
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

  class Tx
    ## TODO
  end

  class Block
    attr_accessor :prev_hash
    attr_accessor :height, :bits, :nonce
    attr_accessor :time, :hash
    attr_accessor :blkblock
    attr_accessor :jsonstr
    attr_accessor :genesis
    
    attr_accessor :next, :prev

    def self.new_genesis()
      obj = self.new
      obj.genesis   = true
      obj.nonce     = GENESIS_NONCE
      obj.bits      = GENESIS_BITS
      obj.time      = GENESIS_TIME
      obj.prev_hash = 0
      obj.height    = 0
      obj.jsonstr   = ""
      obj.prev      = []
      obj.next      = []
      obj.hash      = nil
      return obj
    end

    def self.new_block(prev_hash, nonce, bits, time, height, payloadstr)
      obj = self.new
      obj.prev_hash  = prev_hash.to_i(16)
      obj.genesis = false
      obj.nonce   = nonce
      obj.bits    = bits
      obj.time    = time
      obj.height  = height
      obj.jsonstr = payloadstr
      obj.prev    = []
      obj.next    = []
      obj.hash    = nil
      return obj
    end

    def self.parse_json(jsonstr)
      jsonhash = JSON.parse(jsonstr)
      raise Tinycoin::Errors::InvalidUnknownFormat if not jsonhash["type"] == "block"
      obj = self.new
      begin
        obj.height    = jsonhash["height"]
        obj.prev_hash = jsonhash["prev_hash"].to_i(16)
        obj.nonce     = jsonhash["nonce"]
        obj.bits      = jsonhash["bits"]
        obj.time      = jsonhash["time"]
        obj.jsonstr   = jsonhash["jsonstr"]
        obj.prev      = []
        obj.next      = []
        obj.hash      = nil
      rescue KeyError => e
        raise Tinycoin::Errors::InvalidFieldFormat
      end
      return obj
    end

    def to_binary_s
      blkblock = generate_blkblock()
      return blkblock.to_binary_s
    end

    def to_sha256hash
      blkblock = generate_blkblock()
      @hash ||= Digest::SHA256.hexdigest(Digest::SHA256.digest(blkblock.to_binary_s)).to_i(16)
      return @hash
    end

    def to_sha256hash_s
      to_sha256hash.to_s(16).rjust(64, '0')
    end

    def refresh
      @blkblock = @hash = nil
    end

    def to_json
      {type: "block", height: @height, prev_hash: @prev_hash.to_s(16).rjust(64, '0'), 
        nonce: @nonce, bit: @bits, time: @time, jsonstr: @jsonstr}.to_json
    end

    private
    def generate_blkblock
      @blkblock ||= Tinycoin::Types::BulkBlock.new(block_id: @height, time: @time, bits: @bits,
                                                   prev_hash: @prev_hash, strlen: @jsonstr.size(),
                                                   payloadstr: @jsonstr, nonce: @nonce)
      return @blkblock
    end
  end
end

