# -*- coding: utf-8 -*-
module Tinycoin::Core
  class Tx
    attr_reader :in_tx
    attr_reader :out_tx
    attr_reader :tx_id

    def self.parse_from_hashs arry
      arry.map {|t| Tx.new.parse_from_hash(t)}
    end

    def parse_from_hash hash
      begin
        @tx_id  = hash.fetch("txid").to_i(16)
        @in_tx  = TxIn.new.parse_from_hash(hash.fetch("vin"))
        @out_tx = TxOut.new.parse_from_hash(hash.fetch("vout"))
        self
      rescue KeyError
        raise Tinycoin::Errors::InvalidFieldFormat
      end
    end

    def set_in tx_in
      @in_tx = tx_in
    end

    def set_out tx_out
      @out_tx = tx_out
    end
    
    def do_sign! wallet
      raise Tinycoin::Errors::NotImplemented
      # blk_tx = generate_blktx
      # digest = Digest::SHA256.digest(blk_tx.to_binary_s)
      # @signature ||= TxValidator.sign_data(wallet.key, digest)
      # @signature
    end

    def initialize
##      @signer_pubkey = [signer_pubkey_hex].pack("H*")
      @in_tx = []
      @out_tx = []
    end

    def parse_tx_from_json json_str
      raise Tinycoin::Errors::NotImplemented
    end

    def self.is_coinbase? tx
      tx.in_tx.to_hash.fetch(:type) == "coinbase"
    end

    def is_coinbase?
      begin
        if @in_tx
          @in_tx.to_hash.fetch(:type) == "coinbase" &&
            @in_tx.to_hash.fetch(:scriptSig).fetch(:asm) == Script.generate_coinbase_in
        else
          false
        end
      rescue KeyError
        return false
      end
    end

    def to_binary_s
      generate_blktx.to_binary_s
    end

    def to_sha256hash_s
      to_sha256hash.to_s(16).rjust(64, '0')
    end

    def to_sha256hash
      blk_tx = generate_blktx
      @tx_id ||= Digest::SHA256.hexdigest(Digest::SHA256.digest(blk_tx.to_binary_s)).to_i(16)
      @tx_id
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      {
        txid: to_sha256hash_s,
        vin:  @in_tx.to_hash,
        vout: @out_tx.to_hash,
      }
    end

    private
    def generate_blktx
      # raise Tinycoin::Errors::NoSignedTx unless @signature
      # pubkey = @signer_pubkey.unpack("C*")
      @blk_tx_in = Tinycoin::Types::BulkTxOut.new(amount: 1, )
      @blk_tx ||= Tinycoin::Types::BulkTx.new
      @blk_tx
    end
  end
end
