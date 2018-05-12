# -*- coding: utf-8 -*-
require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Tx" do
  it "should search store for tx_out" do
    @store = Tinycoin::Core::TxStore.new
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair

    tx_out = Tinycoin::Core::TxOut.new
    tx_out.set_coinbase!(@wallet)

    hash_str = tx_out.to_sha256hash_s

    @store.put_uxto(hash_str, tx_out)
    uxto = @store.get_uxto_by_hash(hash_str)
    expect(uxto.to_sha256hash_s).to eq(hash_str)

    uxtos = @store.get_uxto_by_address(@wallet.address)
    expect(uxtos.size).to eq(1)
    expect(uxtos.first.to_sha256hash_s).to eq(hash_str)
    
    expect{
      tx_out2 = Tinycoin::Core::TxOut.new
      wallet2 = Tinycoin::Core::Wallet.new
      wallet2.generate_key_pair
      tx_out2.set_coinbase!(wallet2)
      
      @store.get_uxto_by_hash(tx_out2.to_sha256hash_s)
    }.to raise_error(Tinycoin::Errors::NoSuchTx)
  end
end
