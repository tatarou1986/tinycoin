require_relative 'spec_helper.rb'

describe "Tinycoin::Core::TxValidator" do
end

def generate_key_pair
  # [private_key, public_key]
  ["3b714930efe7663ab4d8ea33926471302b494bf0e90713ec562d969146219c99",
   "04eb86c5eea51550c9ad324b8c8bfb395d7257860c0080270897248bca2e97977afb3e6d07a01b4eb48f5b980998acb7f0eb9011d5ad9f5fdf5986026347a5f6a3"]
end

describe "Tinycoin::Core::TxIn" do
  it "should generate a new coinbase txin" do
    wallet = Tinycoin::Core::Wallet.new
    wallet.generate_key_pair
    
    # priv_key_hex = wallet.private_key
    # pub_key_hex  = wallet.public_key
    tx_in = Tinycoin::Core::TxIn.new(coinbase = true)
    expect(tx_in).not_to eq(nil)
  end
end

describe "Tinycoin::Core::TxOut" do
  it 'shoud generate a new coinbase txout' do
    wallet = Tinycoin::Core::Wallet.new
    wallet.generate_key_pair
    
    tx_out = Tinycoin::Core::TxOut.new(coinbase = true)
    expect(tx_out).not_to eq(nil)
  end
end

describe "Tinycoin::Core::Tx" do
  it 'should generate a new coinbase tx' do
    wallet = Tinycoin::Core::Wallet.new
    wallet.generate_key_pair
    
    # # priv_key_hex = wallet.private_key
    # # pub_key_hex  = wallet.public_key
    
    # tx = Tinycoin::Core::Tx.new
    # tx.do_sign!(wallet)

    # tx_in = Tinycoin::Core::TxIn.new(coinbase = true)
    # tx.set_in(tx_in)

    # tx_out = Tinycoin::Core::TxOut.new(coinbase = true)
    # tx.set_out(tx_out)

    # p tx.to_json
    tx = Tinycoin::Core::TxBuilder.make_coinbase(wallet)
    expect(tx.is_coinbase?).to eq(true)
  end
end

describe "Tinycoin::Core::TxValidator" do
end

describe "Tinycoin::Core::BlockBuilder" do
  it "should generate a block that includes a genesis tx for miner by BlockBuilder" do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.address
    coinbase = Tinycoin::Core::TxBuilder.make_coinbase(@wallet)
  end
end
