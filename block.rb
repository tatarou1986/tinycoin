module Tinycoin::Core
  class Block
    attr_accessor :prev_hash
    attr_accessor :height, :bits, :nonce
    attr_accessor :time, :hash
    attr_accessor :blkblock
    attr_accessor :jsonstr
    attr_accessor :genesis
    attr_accessor :txs
    
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
      obj.txs       = []
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
      obj.txs     = []
      return obj
    end

    def self.parse_json jsonstr, include_hash = false
      jsonhash = JSON.parse(jsonstr)
      new_block_from_hash(jsonhash, include_hash)
    end

    def self.new_block_from_hash hashed_json, include_hash = false
      raise Tinycoin::Errors::InvalidUnknownFormat if not hashed_json["type"] == "block"
      begin
        obj = self.new
        obj.height    = hashed_json.fetch("height")
        obj.prev_hash = hashed_json.fetch("prev_hash").to_i(16)
        obj.nonce     = hashed_json.fetch("nonce")
        obj.bits      = hashed_json.fetch("bits")
        obj.time      = hashed_json.fetch("time")
        obj.jsonstr   = hashed_json.fetch("jsonstr")
        obj.prev      = []
        obj.next      = []
        obj.hash      = nil
        obj.txs       = Tx.parse_from_hashs(hashed_json.fetch("txs"))
        if include_hash
          hash = hashed_json["hash"].to_i(16)
          raise Tinycoin::Errors::InvalidFieldFormat if hash == 0
          raise Tinycoin::Errors::InvalidBlock unless validate_block_hash(obj, hashed_json["hash"])
          obj.hash = hash
        end
        return obj
      rescue KeyError
        raise Tinycoin::Errors::InvalidFieldFormat
      end
    end
    
    def self.validate_block_hash block, hash_hexstr
      truehash = Digest::SHA256.hexdigest(Digest::SHA256.digest(block.to_binary_s)).to_i(16)
      truehash == hash_hexstr.to_i(16) ? true : false
    end

    def add_tx_as_first tx
      @txs[0] = tx
    end

    def add_tx tx
      @txs << tx
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

    def to_hash
      { type:      "block",
        height:    @height,
        prev_hash: @prev_hash.to_s(16).rjust(64, '0'), 
        hash:      to_sha256hash_s, 
        nonce:     @nonce,
        bits:      @bits,
        time:      @time,
        txs:       @txs.map {|t| t.to_hash},
        jsonstr:   @jsonstr
      }
    end

    def to_json
      to_hash.to_json
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
