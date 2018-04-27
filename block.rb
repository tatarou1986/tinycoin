module Tinycoin::Core
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

    def self.parse_json jsonstr, include_hash = false
      jsonhash = JSON.parse(jsonstr)
      new_block_from_hash(jsonhash, include_hash)
    end

    def self.new_block_from_hash hashed_json, include_hash = false
      raise Tinycoin::Errors::InvalidUnknownFormat if not hashed_json["type"] == "block"
      obj = self.new
      obj.height    = if hashed_json["height"] then hashed_json["height"] else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.prev_hash = if hashed_json["prev_hash"] then hashed_json["prev_hash"].to_i(16) else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.nonce     = if hashed_json["nonce"] then hashed_json["nonce"] else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.bits      = if hashed_json["bits"] then hashed_json["bits"] else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.time      = if hashed_json["time"] then hashed_json["time"] else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.jsonstr   = if hashed_json["jsonstr"] then hashed_json["jsonstr"] else raise Tinycoin::Errors::InvalidFieldFormat end
      obj.prev      = []
      obj.next      = []
      obj.hash      = nil
      if include_hash
        hash = hashed_json["hash"].to_i(16)
        raise Tinycoin::Errors::InvalidFieldFormat if hash == 0
        raise Tinycoin::Errors::InvalidBlock unless validate_block_hash(obj, hashed_json["hash"])
        obj.hash = hash
      end
      return obj
    end
    
    def self.validate_block_hash block, hash_hexstr
      truehash = Digest::SHA256.hexdigest(Digest::SHA256.digest(block.to_binary_s)).to_i(16)
      truehash == hash_hexstr.to_i(16) ? true : false
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
      {type: "block", height: @height, prev_hash: @prev_hash.to_s(16).rjust(64, '0'), 
        hash: to_sha256hash_s, 
        nonce: @nonce, bits: @bits, time: @time, jsonstr: @jsonstr}
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
