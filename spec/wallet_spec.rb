require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Wallet" do
  it 'should validate signature from ' do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.generate_key_pair
    privkey_hex = @wallet.private_key
    pubkey_hex  = @wallet.public_key
    pubkey_bin = [pubkey_hex].pack("H*")
    privkey_bin = [privkey_hex].pack("H*")
    signature = Bitcoin::Secp256k1.sign("derp", privkey_bin)
    expect(Bitcoin::Secp256k1.verify("derp", signature, pubkey_bin)).to eq(true)
    expect(Bitcoin::Secp256k1.verify("DERP", signature, pubkey_bin)).to eq(false)
  end
end
