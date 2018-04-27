require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Wallet" do
  it 'should return key pairs' do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair
    priv = @wallet.private_key
    pub  = @wallet.public_key
    p priv
    p pub
    expect(priv).not_to eq(nil)
    expect(pub).not_to eq(nil)
  end

  it 'should return key pairs' do
    @wallet = Tinycoin::Core::Wallet.new
    address = @wallet.address
    p address
    expect(address).not_to eq(nil)
  end
end
