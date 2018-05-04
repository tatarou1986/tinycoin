# -*- coding: utf-8 -*-
module Tinycoin::Core
  class TxValidator

    # txidがvalidかどうかチェックする
    # +tx+ jsonからパース済みのTxインスタンス
    def self.validate_txs txs
      wallet = Tinycoin::Core::Wallet.new

      # txsが0ということはありえない。少なくともcoinbaseは含む
      raise Tinycoin::Errors::InvalidTx if txs.size == 0
      
      coinbase_processed = false
      txs.each_with_index {|tx, i|
        # scriptを走らせるVMを作成
        vm  = Tinycoin::Core::VM.new
        if tx.is_coinbase?
          # coinbaseは2つ以上存在してはならない
          raise Tinycoin::Errors::InvalidTx if coinbase_processed
          # coinbaseは必ず一番目でなければならない
          raise Tinycoin::Errors::InvalidTx unless i == 0
          # coinbaseの場合は1コインのみ支払われる
          raise Tinycoin::Errors::InvalidTx unless tx.out_tx.amount == 1
          # addressがvalidであること
          raise Tinycoin::Errors::InvalidTx if tx.out_tx.address.size == 0
          raise Tinycoin::Errors::InvalidTx unless wallet.valid_address?(tx.out_tx.address)

          # coinbaseは処理済み
          coinbase_processed = true
        else
          # TODO coinbase以外
          raise Tinycoin::Errors::InvalidTx
        end

        # トランザクションに含まれるスクリプトを実行
        vm.execute!(Script.parse(tx.in_tx.script_sig))
        vm.execute!(Script.parse(tx.out_tx.script_pubkey))

        # スクリプトがtrueを返さなければ不正なトランザクション
        raise Tinycoin::Errors::InvalidTx unless vm.ret_true?
      }

      return true
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
