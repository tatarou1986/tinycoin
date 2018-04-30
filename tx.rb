# -*- coding: utf-8 -*-
module Tinycoin::Core
  class Tx
    attr_reader :in_tx
    attr_reader :out_tx
    attr_reader :signature
    attr_reader :hash
    attr_reader :signer_pubkey
    attr_reader :amount

    # def self.new_tx signer_pubkey_hexstr, amount
    # end

    def add_in_tx tx
    end

    def add_out_tx tx
    end
    
    def do_sign! privkey_hex
      privkey_bin = [privkey_hex].pack("H*")
      @signature = Bitcoin::Secp256k1.sign("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", privkey_bin)
      @signature
    end

    def initialize signer_pubkey_hex, amount
      @in_tx = "hello"
      @out_tx = "world"
      @signer_pubkey = [signer_pubkey_hex].pack("H*")
      @amount = amount
    end

    def to_binary_s
      generate_blktx.to_binary_s
    end

    def to_sha256hash_s
      to_sha256hash.to_s(16).rjust(64, '0')
    end

    def to_sha256hash
      blk_tx = generate_blktx
      @hash ||= Digest::SHA256.hexdigest(Digest::SHA256.digest(blk_tx.to_binary_s)).to_i(16)
      @hash
    end

    private
    def generate_blktx
      #      raise Tinycoin::Errors::NoSignedTx unless @signature
      pubkey = @signer_pubkey.unpack("C*")
      @blk_tx ||= Tinycoin::Types::BulkTx.new(signer_pubkey: pubkey,
                                              signature: [],
                                              amount: @amount)
      @blk_tx
    end
  end
end
