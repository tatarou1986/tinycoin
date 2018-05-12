# -*- coding: utf-8 -*-
require_relative 'spec_helper.rb'

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
    
    tx_out = Tinycoin::Core::TxOut.new
    tx_out.set_coinbase!(wallet)
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
  it "should validate txs" do
#     orig_block = Tinycoin::Core::Block.new_block(prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
#                                                  nonce     = 1264943, 
#                                                  bits      = 26229296,
#                                                  time      = 1458902575, 
#                                                  height    = 0, 
#                                                  payloadstr = "")
#     orig_block_hash_str = orig_block.to_sha256hash_s
    
#     jsonstr=<<JSON
# { 
#   "type": "block",
#   "height": 0,
#   "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
#   "hash": "#{orig_block_hash_str}",
#   "nonce": 1264943,
#   "bits": 26229296,
#   "time": 1458902575,
#   "txs" :[{"txid" : "1596d82958b4b5474565627bc40dd23f48aa50a375ba06b25e4b8ad953105f51",
#            "vin"  :{"type": "coinbase",
#                     "scriptSig" : {"asm": "OP_NOP"}},
#            "vout" :{"type"  : "coinbase",
#                     "value" : 1,
#                     "scriptPubKey" :{"asm": "OP_PUSH true", "address": "moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe" }}
#           }],
#   "jsonstr": ""
# }
# JSON
#     test_block = Tinycoin::Core::Block.parse_json(jsonstr)
#     ret = Tinycoin::Core::TxValidator.validate_txs(test_block.txs)
#     expect(ret).to eq(true)
  end

  it "should not validate that includes illegal fields 1" do
#     orig_block = Tinycoin::Core::Block.new_block(
#           prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
#           nonce     = 1264943, 
#           bits      = 26229296,
#           time      = 1458902575, 
#           height    = 0, 
#           payloadstr = ""
#     )
#     orig_block_hash_str = orig_block.to_sha256hash_s

#     # coinbaseなのにvalueが2ある
#     jsonstr=<<JSON
# { 
#   "type": "block",
#   "height": 0,
#   "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
#   "hash": "#{orig_block_hash_str}",
#   "nonce": 1264943,
#   "bits": 26229296,
#   "time": 1458902575,
#   "txs" :[{"txid" : "1596d82958b4b5474565627bc40dd23f48aa50a375ba06b25e4b8ad953105f51",
#            "vin"  :{"type": "coinbase",
#                     "scriptSig" : {"asm": "OP_NOP"}},
#            "vout" :{"type"  : "coinbase",
#                     "value" : 2,
#                     "scriptPubKey" :{"asm": "OP_PUSH true", "address": "moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe" }}
#           }],
#   "jsonstr": ""
# }
# JSON
#     test_block = Tinycoin::Core::Block.parse_json(jsonstr)
#     expect{ Tinycoin::Core::TxValidator.validate_txs(test_block.txs) }.to raise_error(Tinycoin::Errors::InvalidTx)
  end

  it "should not validate that includes illegal fields 2" do
#     orig_block = Tinycoin::Core::Block.new_block(
#           prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
#           nonce     = 1264943, 
#           bits      = 26229296,
#           time      = 1458902575, 
#           height    = 0, 
#           payloadstr = ""
#     )
#     orig_block_hash_str = orig_block.to_sha256hash_s

#     # coinbaseが2つある
#     jsonstr=<<JSON
# { 
#   "type": "block",
#   "height": 0,
#   "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
#   "hash": "#{orig_block_hash_str}",
#   "nonce": 1264943,
#   "bits": 26229296,
#   "time": 1458902575,
#   "txs" :[{"txid" : "1596d82958b4b5474565627bc40dd23f48aa50a375ba06b25e4b8ad953105f51",
#            "vin"  :{"type": "coinbase",
#                     "scriptSig" : {"asm": "OP_NOP"}},
#            "vout" :{"type"  : "coinbase",
#                     "value" : 2,
#                     "scriptPubKey" :{"asm": "OP_PUSH true", "address": "moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe" }}},
#          {"txid" : "1596d82958b4b5474565627bc40dd23f48aa50a375ba06b25e4b8ad953105f51",
#            "vin"  :{"type": "coinbase",
#                     "scriptSig" : {"asm": "OP_NOP"}},
#            "vout" :{"type"  : "coinbase",
#                     "value" : 2,
#                     "scriptPubKey" :{"asm": "OP_PUSH true", "address": "moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe" }}}
#   ],
#   "jsonstr": ""
# }
# JSON
#     test_block = Tinycoin::Core::Block.parse_json(jsonstr)
#     expect{ Tinycoin::Core::TxValidator.validate_txs(test_block.txs) }.to raise_error(Tinycoin::Errors::InvalidTx)
  end
end

describe "Tinycoin::Core::TxValidator" do
end
