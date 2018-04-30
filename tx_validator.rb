# -*- coding: utf-8 -*-
module Tinycoin::Core
  class TxValidator
    
    def validate pubkey_hex_str, tx
    end

    # 署名検証に使うECパラメータ使用のための一時的な鍵ペア生成関数
    def self.generate_ec_pkey
      ::OpenSSL::PKey::EC.new("secp256k1")
    end

    # EC署名検証
    # hex stringで与えられた+pub_key+と
    # hex stringで与えられた+signature+と
    # hex stringで与えられた+hash+ (sha256でOK)
    # を元に、署名検証する
    def self.verify_signature hash, signature, pub_key
      begin
        key = generate_ec_pkey
        key.public_key = ::OpenSSL::PKey::EC::Point.from_hex(key.group, pub_key)
        signature = Bitcoin::OpenSSL_EC.repack_der_signature(signature)
        if signature
          key.dsa_verify_asn1(hash, signature)
        else
          false
        end
      rescue OpenSSL::PKey::ECError, OpenSSL::PKey::EC::Point::Error, OpenSSL::BNError
        false
      end
    end

    def self.sign_data key, data
      sig = key.dsa_sign_asn1(data)
      return sig
    end
  end
end
