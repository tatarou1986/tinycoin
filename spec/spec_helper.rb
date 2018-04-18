$: << File.expand_path(File.join(File.dirname(__FILE__), '../'))

module Tinycoin
  autoload :Errors, "errors.rb"
  autoload :Node, "node.rb"
  autoload :Core, "blockchain.rb"
  autoload :Types, "block.rb"
  autoload :Logger, "logger.rb"
  
  class TestBlock
    attr_accessor :next
    attr_accessor :prev_hash
    attr_accessor :hash
    attr_accessor :bits

    def initialize(prev_hash, hash)
      @prev_hash = prev_hash
      @hash      = hash
      @next      = []
      @bits      = 0x1effffff
    end

    def to_sha256hash_s()
      return @hash
    end    
  end
end
