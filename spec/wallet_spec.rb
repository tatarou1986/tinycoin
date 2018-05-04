# -*- coding: utf-8 -*-

require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Wallet" do
  it 'should generate a key pair by secp256k1' do
    @wallet = Tinycoin::Core::Wallet.new
    pair = @wallet.generate_key_pair
    privkey_hex = @wallet.private_key
    pubkey_hex  = @wallet.public_key

    expect(pair).not_to eq(nil)
    expect(privkey_hex).not_to eq(nil)
    expect(pubkey_hex).not_to  eq(nil)
  end

  it 'should return key pairs' do
    @wallet = Tinycoin::Core::Wallet.new
    address = @wallet.address
    puts "address: #{address}"
    expect(address).not_to eq(nil)
  end

  it 'should sign and validate signature from the wallet address' do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair
    # pubkey_bin = [pubkey_hex].pack("H*")
    # privkey_bin = [privkey_hex].pack("H*")

    # 署名対象データ
    b = [
         "\x47\xa0\x22\x8b\x06\xc9\x36\x8f\x96\xc5\xf0\x4e\xb1\x09\xf8\x2c\xef\x36\xda\xe7\xc1\xbf\x25\x4c\x1a\x3f\x78\x61\x5e\xb0\xbe\x83" +
         "\xee\x67\xde\x31\x75\x76\x58\xdd\xd7\x40\x3e\x1a\x35\xd9\xc0\x6a\x5a\x13\xe6\x68\x98\x44\x3b\x45\x8c\xd6\xa7\x1b\x66\x27\x41\x6c" +
         "\xab\x9e\xf9\xbd\xa0\x2c\xad\x27\x90\xef\x9b\xb7\xc9\xa0\x7f\xe1\x79\x1a\x9d\x5a\xe0\x43\x09\xc0\xe9\x06\x48\x19\x19\x4c\x28\x31" +
         "\xff\x51\x61\x01\x80\xf6\x4d\x33\xa8\xc1\xba\x1d\xd9\xa9\xd0\x40\x48\x88\xc9\x6e\xaf\xd1\x57\x03\x64\x35\x8b\xbe\x99\x8f\x2d\xfe" +
         "\x9e\xe4\x18\x36\x7c\x3b\xce\x06\x5e\x7c\x01\x61\x29\x6e\xaa\x0d\x54\x96\xf9\x0f\x8b\x7b\x24\xeb\xf7\x2c\xc4\xba\xa5\x60\x9a\x1f" +
         "\x0b\x35\xf3\x73\x10\xe1\xde\x3f\xa4\xe1\x37\x7c\x02\x12\x62\x20\xe1\x64\xfa\x59\xec\xfe\xdc\xf4\x71\x4e\x61\xad\x74\xcc\x4b\x08"
        ].pack("H*")
    b_hash = Digest::SHA256.digest(b)
    # 署名対象データのsha256に対して署名する
    sign_b = Tinycoin::Core::TxValidator.sign_data(@wallet.key, b_hash)
    expect(sign_b).not_to eq(nil)


    # bと同じデータ
    b2 = [
         "\x47\xa0\x22\x8b\x06\xc9\x36\x8f\x96\xc5\xf0\x4e\xb1\x09\xf8\x2c\xef\x36\xda\xe7\xc1\xbf\x25\x4c\x1a\x3f\x78\x61\x5e\xb0\xbe\x83" +
         "\xee\x67\xde\x31\x75\x76\x58\xdd\xd7\x40\x3e\x1a\x35\xd9\xc0\x6a\x5a\x13\xe6\x68\x98\x44\x3b\x45\x8c\xd6\xa7\x1b\x66\x27\x41\x6c" +
         "\xab\x9e\xf9\xbd\xa0\x2c\xad\x27\x90\xef\x9b\xb7\xc9\xa0\x7f\xe1\x79\x1a\x9d\x5a\xe0\x43\x09\xc0\xe9\x06\x48\x19\x19\x4c\x28\x31" +
         "\xff\x51\x61\x01\x80\xf6\x4d\x33\xa8\xc1\xba\x1d\xd9\xa9\xd0\x40\x48\x88\xc9\x6e\xaf\xd1\x57\x03\x64\x35\x8b\xbe\x99\x8f\x2d\xfe" +
         "\x9e\xe4\x18\x36\x7c\x3b\xce\x06\x5e\x7c\x01\x61\x29\x6e\xaa\x0d\x54\x96\xf9\x0f\x8b\x7b\x24\xeb\xf7\x2c\xc4\xba\xa5\x60\x9a\x1f" +
         "\x0b\x35\xf3\x73\x10\xe1\xde\x3f\xa4\xe1\x37\x7c\x02\x12\x62\x20\xe1\x64\xfa\x59\xec\xfe\xdc\xf4\x71\x4e\x61\xad\x74\xcc\x4b\x08"
        ].pack("H*")
    b2_hash = Digest::SHA256.digest(b2)

    # 署名検証に必要なものは 署名対象となったデータのハッシュ, 署名, 署名者の公開鍵
    valid = Tinycoin::Core::TxValidator.verify_signature(b2_hash, sign_b, @wallet.public_key)
    expect(valid).to eq(true)

    # b, b2とは少し違うデータ
    b3 = [
          "\x47\xa0\x22\x8b\x06\xc9\x36\x8f\x96\xc5\xf0\x4e\xb1\x09\xf8\x2c\xef\x36\xda\xe7\xc1\xbf\x25\x4c\x1a\x3f\x78\x61\x5e\xb0\xbe\x82" +
          "\xee\x67\xde\x31\x75\x76\x58\xdd\xd7\x40\x3e\x1a\x35\xd9\xc0\x6a\x5a\x13\xe6\x68\x98\x44\x3b\x45\x8c\xd6\xa7\x1b\x66\x27\x41\x6c" +
          "\xab\x9e\xf9\xbd\xa0\x2c\xad\x27\x90\xef\x9b\xb7\xc9\xa0\x7f\xe1\x79\x1a\x9d\x5a\xe0\x43\x09\xc0\xe9\x06\x48\x19\x19\x4c\x28\x31" +
          "\xff\x51\x61\x01\x80\xf6\x4d\x33\xa8\xc1\xba\x1d\xd9\xa9\xd0\x40\x48\x88\xc9\x6e\xaf\xd1\x57\x03\x64\x35\x8b\xbe\x99\x8f\x2d\xfe" +
          "\x9e\xe4\x18\x36\x7c\x3b\xce\x06\x5e\x7c\x01\x61\x29\x6e\xaa\x0d\x54\x96\xf9\x0f\x8b\x7b\x24\xeb\xf7\x2c\xc4\xba\xa5\x60\x9a\x1f" +
          "\x0b\x35\xf3\x73\x10\xe1\xde\x3f\xa4\xe1\x37\x7c\x02\x12\x62\x20\xe1\x64\xfa\x59\xec\xfe\xdc\xf4\x71\x4e\x61\xad\x74\xcc\x4b\x08"
         ].pack("H*")
    b3_hash = Digest::SHA256.digest(b3)
    # 署名検証に必要なものは 署名対象となったデータのハッシュ, 署名, 署名者の公開鍵
    valid = Tinycoin::Core::TxValidator.verify_signature(b3_hash, sign_b, @wallet.public_key)

    # b3はb, b2とはちがうので当然署名結果はfalse
    expect(valid).to eq(false)
  end
end
