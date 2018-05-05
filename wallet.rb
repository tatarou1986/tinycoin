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
      Wallet.encode_base58(get_address(public_key))
    end

    def valid_address? address
      Wallet.decode_base58(address) rescue return false
      true
    end

    def self.encode_base58(hex)
      leading_zero_bytes  = (hex.match(/^([0]+)/) ? $1 : '').size / 2
      ("1"*leading_zero_bytes) + int_to_base58( hex.to_i(16) )
    end

    def self.decode_base58(base58_val)
      s = base58_to_int(base58_val).to_s(16); s = (s.bytesize.odd? ? '0'+s : s)
      s = '' if s == '00'
      leading_zero_bytes = (base58_val.match(/^([1]+)/) ? $1 : '').size
      s = ("00"*leading_zero_bytes) + s  if leading_zero_bytes > 0
      s
    end

    def self.base58_to_hex(base58_val)
      decode_base58(base58_val)
    end

    private
    def self.int_to_base58(int_val, leading_zero_bytes=0)
      alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      base58_val, base = '', alpha.size
      while int_val > 0
        int_val, remainder = int_val.divmod(base)
        base58_val = alpha[remainder] + base58_val
      end
      base58_val
    end

    def self.base58_to_int(base58_val)
      alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      int_val, base = 0, alpha.size
      base58_val.reverse.each_char.with_index do |char,index|
        raise ArgumentError, 'Value not a valid Base58 String.' unless char_index = alpha.index(char)
        int_val += char_index*(base**index)
      end
      int_val
    end
    
    def get_address pubkey_hex
      bytes = [pubkey_hex].pack("H*")
      Digest::RMD160.hexdigest(Digest::SHA256.digest(bytes))
    end
  end
end
