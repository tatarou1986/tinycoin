# -*- coding: utf-8 -*-

require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Wallet" do
  it 'should generate a key pair by secp256k1' do
    @wallet = Tinycoin::Core::Wallet.new
    pair = @wallet.generate_key_pair
    expect(pair).not_to eq(nil)
  end

  it 'should return key pairs' do
    @wallet = Tinycoin::Core::Wallet.new
    address = @wallet.address
    expect(address).not_to eq(nil)
  end

  it 'should validate signature from the wallet address' do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair
    privkey_hex = @wallet.private_key
    pubkey_hex  = @wallet.public_key
    pubkey_bin = [pubkey_hex].pack("H*")
    privkey_bin = [privkey_hex].pack("H*")
    signature = Bitcoin::Secp256k1.sign("derp", privkey_bin)
    expect(Bitcoin::Secp256k1.verify("derp", signature, pubkey_bin)).to eq(true)
    expect(Bitcoin::Secp256k1.verify("DERP", signature, pubkey_bin)).to eq(false)
    ##    signature = Bitcoin::Secp256k1.sign("derp", privkey_bin)
    # # 署名からpublickeyは復活させられる
    # pub2 = Bitcoin::Secp256k1.recover_compact("derp", signature)
    # expect(pub2).to eq(pubkey_bin)
  end
end
