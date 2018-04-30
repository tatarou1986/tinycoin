require_relative 'spec_helper.rb'

describe "Tinycoin::Core::TxValidator" do
end

def generate_key_pair
  # [private_key, public_key]
  ["3b714930efe7663ab4d8ea33926471302b494bf0e90713ec562d969146219c99",
   "04eb86c5eea51550c9ad324b8c8bfb395d7257860c0080270897248bca2e97977afb3e6d07a01b4eb48f5b980998acb7f0eb9011d5ad9f5fdf5986026347a5f6a3"]
end

describe "Tinycoin::Core::Tx" do
  it 'should generate a new tx' do
    # priv_key, pub_key = generate_key_pair
    # tx = Tinycoin::Core::Tx.new(pub_key, 10)
    # p tx.do_sign!(priv_key)
    # p tx.to_sha256hash_s
  end
end
