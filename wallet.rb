module Tinycoin::Core
  class Wallet
    attr_reader :key
    
    def initialize
      @key = nil
    end
    
    def generate_key_pair
      @key ||= ::OpenSSL::PKey::EC.new("secp256k1").generate_key
    end

    def private_key
      @key.private_key_hex
    end

    def public_key
      @key.public_key_hex
    end

    def address
      generate_key_pair
      get_address(public_key)
    end

    private
    def get_address pubkey_hex
      bytes = [pubkey_hex].pack("H*")
      Digest::RMD160.hexdigest(Digest::SHA256.digest(bytes))
    end
  end
end
