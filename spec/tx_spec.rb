require_relative 'spec_helper.rb'

describe "Tinycoin::Core::TxValidator" do
  it 'should a signature varify by Secp256k1.' do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair
  end

  it 'should return key pairs' do
    @wallet = Tinycoin::Core::Wallet.new
    address = @wallet.address
    expect(address).not_to eq(nil)
  end
end
