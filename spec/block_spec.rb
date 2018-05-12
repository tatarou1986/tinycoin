# -*- coding: utf-8 -*-
require_relative 'spec_helper.rb'

describe "Tinycoin::Core::Block" do  
  context "when the genesis hash has been given" do
    before do
      @genesis = Tinycoin::Core::Block.new_genesis()
    end
    
    describe '#to_sha256hash_s' do
      it 'should make the genesis block as sha256' do
        expect(@genesis.to_sha256hash_s()).to eq(Tinycoin::Core::GENESIS_HASH)
      end
    end

    describe '#to_sha256hash' do
      it 'should make the genesis block sha256hash as binary' do
        expect(@genesis.to_sha256hash).to eq(Tinycoin::Core::GENESIS_HASH.to_i(16))
      end
    end

    describe '#to_json' do
      it 'should convert the genesis block to json' do
        g = Tinycoin::Core::Block.new_genesis()

        jsonstr=<<JSON
{"type":"block","height":0,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","hash":"#{g.to_sha256hash_s}","nonce":#{Tinycoin::Core::GENESIS_NONCE},"bits":520093695,"time":#{Tinycoin::Core::GENESIS_TIME},"txs":[],"jsonstr":""}
JSON
        jsonstr = JSON.parse(jsonstr).to_json
        expect(@genesis.to_json).to eq(jsonstr)
      end
    end

    describe '#to_binary_s' do
      it 'should convert the genesis block to binary' do
        binary = Tinycoin::Types::BulkBlock.new(nonce: Tinycoin::Core::GENESIS_NONCE, block_id: 0,
                                                time: Tinycoin::Core::GENESIS_TIME, bits: Tinycoin::Core::GENESIS_BITS,
                                                prev_hash: 0, strlen: 0, payloadstr: "")
        expect(@genesis.to_binary_s).to eq(binary.to_binary_s)
      end
    end

  end

  context "when a block has been given" do
    describe '#to_sha256hash_s' do
      it 'should make the sha256 hash' do
        block = Tinycoin::Core::Block.new_block(
               prev_hash  = "0000000000000000000000000000000000000000000000000000000000000000",
               nonce      = Tinycoin::Core::GENESIS_NONCE,
               bits       = Tinycoin::Core::GENESIS_BITS,
               time       = Tinycoin::Core::GENESIS_TIME,
               height     = 0,
               payloadstr = ""                                               
        )
        expect(block.to_sha256hash_s()).to eq(Tinycoin::Core::GENESIS_HASH)
      end
    end
  end

  context "when a bad json has been given" do
    describe "#parse_json" do
      it 'should be raise a error 1' do
        json = "{\"type\" : \"aaaa\"}"        
        expect{ Tinycoin::Core::Block.parse_json(json) }.to raise_error(Tinycoin::Errors::InvalidUnknownFormat)
      end

      it 'should be raise a error 2' do
        orig_block = Tinycoin::Core::Block.new_block(prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
                                                     nonce     = 1264943, 
                                                     bits      = 26229296,
                                                     time      = 1458902575, 
                                                     height    = 0, 
                                                     payloadstr = "")
        orig_block_hash_str = orig_block.to_sha256hash_s
        
        # 重要なフィールドが足りないjson
        json=<<JSON
{ 
  "type": "block",
  "height": 0,
  "hash": "#{orig_block_hash_str}",
  "nonce": 1264943,
  "bits": 26229296,
  "time": 1458902575,
  "txs": [],
  "jsonstr": ""
}
JSON
        expect{ Tinycoin::Core::Block.parse_json(json) }.to raise_error(Tinycoin::Errors::InvalidFieldFormat)
      end
    end
  end
  
  context "when a good json has been given" do
    describe "#parse_json" do
      it 'should accept the json string' do
        # TODO: このテストはほとんど意味がないので後でちゃんと変えること
#         @hash = []
#         @hash[0] = "0000000000000000000000000000000000000000000000000000000000000000"
#         orig_block = Tinycoin::Core::Block.new_block(
#                 prev_hash = @hash[0],
#                 nonce     = 1264943, 
#                 bits      = 26229296,
#                 time      = 1458902575, 
#                 height    = 0, 
#                 payloadstr = ""
#         )

#         @wallet = Tinycoin::Core::Wallet.new  
#         @wallet.generate_key_pair
        
#         @tx = Tinycoin::Core::Tx.new
        
#         tx_in  = Tinycoin::Core::TxIn.new(coinbase = true)
#         tx_out = Tinycoin::Core::TxOut.new
#         tx_out.set_coinbase!(@wallet)

#         @tx.set_in(tx_in)
#         @tx.set_out(tx_out)

#         orig_block.add_tx_as_first(@tx)
#         orig_block_hash_str = orig_block.to_sha256hash_s
       
#         @block = Tinycoin::Core::BlockBuilder.make_block_as_miner(
#                 @wallet,
#                 @hash[0],
#                 1264943,
#                 26229296,
#                 1458902575,
#                 0
#         )
#         jsonstr=<<JSON
# { 
#   "type": "block",
#   "height": 0,
#   "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
#   "hash": "bf382debd0643f0af7a051e88d931afaae10b11b3fa2d6a9c3a9ff81f3a29dae",
#   "nonce": 1264943,
#   "bits": 26229296,
#   "time": 1458902575,
#   "txs" :[{"txid" : "55f3d8d464b70de976ef828b5d31225babe532adf76f46440e4ce0e857d6fdc4",
#            "vin"  :{"type": "coinbase",
#                     "scriptSig" : {"asm": "OP_NOP"}},
#            "vout" :{"type"  : "coinbase",
#                     "value" : 1,
#                     "locktime" : 1458902575,
#                     "scriptPubKey" :{"asm": "OP_PUSH true", "address": "#{@wallet.address}" }}
#           }],
#   "jsonstr": ""
# }
# JSON
#         test_block = Tinycoin::Core::Block.parse_json(jsonstr)
#         expect(test_block.prev_hash).to eq(0)
#         expect(test_block.height).to eq(0)
#         expect(test_block.nonce).to eq(1264943)
#         expect(test_block.time).to eq(1458902575)
#         expect(test_block.bits).to eq(26229296)
#         expect(test_block.jsonstr).to eq("")
#         expect(test_block.to_sha256hash_s).to eq(orig_block_hash_str)

#         expect(test_block.txs.size).to eq(1)
#         expect(test_block.txs.first.is_coinbase?).to eq(true)
#         expect(test_block.txs.first.out_tx.address).to eq(@wallet.address)
#         expect(Tinycoin::Core::Wallet.valid_address?(test_block.txs.first.out_tx.address)).to eq(true)
#         expect(test_block.txs.first.out_tx.address).not_to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VR3")

#         # BlockIdがvalidであるはず
#         # IxIdがvalidであるはず
      end

      it 'should deny the json string if the hash field is invalid' do
        orig_block = Tinycoin::Core::Block.new_block(prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
                                                     nonce     = 1264943, 
                                                     bits      = 26229296,
                                                     time      = 1458902575, 
                                                     height    = 0, 
                                                     payloadstr = "")
        orig_block_hash_str = orig_block.to_sha256hash_s

        # hashフィールドが不正
        jsonstr=<<JSON
{ 
  "type": "block",
  "height": 0,
  "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
  "hash": "ffffffffffffffffffffffffffff",
  "nonce": 1264943,
  "bits": 26229296,
  "time": 1458902575,
  "txs": [],
  "jsonstr": ""
}
JSON
        expect{ Tinycoin::Core::Block.parse_json(jsonstr, true) }.to raise_error(Tinycoin::Errors::InvalidBlock)
      end
    end
  end

  it "should validate a block from json" do
    jsonstr=<<JSON
{"type":"block","height":1,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","hash":"00008df37fbcdbe1945d815e7f36906f399c31aa139c7d7ebd25af134ccad853","nonce":155257,"bits":26229296,"time":1526140635,"txs":[{"txid":"e44eced7f5594a6cea8d7da34dcb8b0ac55e2ba0748ca41d84adb57b1cb26812","vin":{"type":"coinbase","scriptSig":{"asm":"OP_NOP"}},"vout":{"type":"coinbase","hash":"0c9c81983f40fea6c7c873905e2315634fbb2a6741cc52bafd82b25f0c3e4bb5","value":1,"locktime":1526140635,"scriptPubKey":{"asm":"OP_PUSH true","address":"4EBE8inCfT4GaLRqKztWnWTmzHZt"}}}],"jsonstr":""}
JSON

    @block = Tinycoin::Core::Block.validate_block_json(jsonstr, Tinycoin::Core::GENESIS_BITS)
    expect(@block).not_to eq(nil)

    expect(@block.prev_hash).to eq(0)
    expect(@block.height).to    eq(1)
    expect(@block.nonce).to     eq(155257)
    expect(@block.bits).to      eq(26229296)
    expect(@block.jsonstr).to   eq("")
    expect(@block.time).to      eq(1526140635)
    expect(@block.txs.first.is_coinbase?).to eq(true)
    expect(@block.txs.first.out_tx.address).to eq("4EBE8inCfT4GaLRqKztWnWTmzHZt")
    expect(@block.txs.first.out_tx.locktime).to eq(1526140635)
    expect(Tinycoin::Core::Wallet.valid_address?(@block.txs.first.out_tx.address)).to eq(true)
    expect(@block.txs.first.out_tx.address).not_to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VR3")
  end

  it "should validate a block from json 2" do
    # blockのhashが微妙に違う
    jsonstr=<<JSON
{"type":"block","height":1,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","hash":"00008df37fbcdbe1945d815e7f36906f399c31aa139c7d7ebd25af134ccad800","nonce":155257,"bits":26229296,"time":1526140635,"txs":[{"txid":"e44eced7f5594a6cea8d7da34dcb8b0ac55e2ba0748ca41d84adb57b1cb26812","vin":{"type":"coinbase","scriptSig":{"asm":"OP_NOP"}},"vout":{"type":"coinbase","hash":"0c9c81983f40fea6c7c873905e2315634fbb2a6741cc52bafd82b25f0c3e4bb5","value":1,"locktime":1526140635,"scriptPubKey":{"asm":"OP_PUSH true","address":"4EBE8inCfT4GaLRqKztWnWTmzHZt"}}}],"jsonstr":""}
JSON
    expect{ Tinycoin::Core::Block.validate_block_json(jsonstr, Tinycoin::Core::GENESIS_BITS) }.to raise_error(Tinycoin::Errors::InvalidBlock)
  end

  it "should validate block and tx from json" do
    jsonstr=<<JSON
{"type":"block","height":1,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","hash":"00004438f37c210e6688f9dc03026bce3707257df84464ecb24162dd3a4d5ca2","nonce":23022,"bits":26229296,"time":1526141094,"txs":[{"txid":"6e3fbfcbad6d519015093b0b8b68d89acc73208aaf9efb57ecc26c279ed710b4","vin":{"type":"coinbase","scriptSig":{"asm":"OP_NOP"}},"vout":{"type":"coinbase","hash":"920dad58971879776e355ecfa418148ab1c0de32808066c30fd94b44eef6feb3","value":1,"locktime":1526141094,"scriptPubKey":{"asm":"OP_PUSH true","address":"ZSk4TKDymvc8NuUc7zaWYXRNCLQ"}}}],"jsonstr":""}
JSON

    @block = Tinycoin::Core::Block.validate_block_json(jsonstr, Tinycoin::Core::GENESIS_BITS)
    expect(@block).not_to eq(nil)

    expect(@block.prev_hash).to eq(0)
    expect(@block.height).to    eq(1)
    expect(@block.nonce).to     eq(23022)
    expect(@block.bits).to      eq(26229296)
    expect(@block.jsonstr).to   eq("")
    expect(@block.time).to      eq(1526141094)
    expect(@block.txs.first.is_coinbase?).to eq(true)
    expect(@block.txs.first.out_tx.address).to eq("ZSk4TKDymvc8NuUc7zaWYXRNCLQ")
    expect(Tinycoin::Core::Wallet.valid_address?(@block.txs.first.out_tx.address)).to eq(true)
    expect(@block.txs.first.out_tx.address).not_to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VR3")

    # トランザクションのvalidationも行ってみる
    ret = Tinycoin::Core::TxValidator.validate_txs(@block.txs)
    expect(ret).to eq(true)
  end
end

describe "Tinycoin::Core::BlockBuilder" do
  it "should generate a block that includes a genesis tx for miner by BlockBuilder" do
    @wallet = Tinycoin::Core::Wallet.new
    @wallet.address
    @block = Tinycoin::Core::BlockBuilder.make_block_as_miner(@wallet, "0000000000000000000000000000000000000000000000000000000000000000", 1264943, 26229296, 1458902575, 1)
    
    expect(@block.prev_hash).to eq(0)
    expect(@block.height).to    eq(1)
    expect(@block.nonce).to     eq(1264943)
    expect(@block.bits).to      eq(26229296)
    expect(@block.jsonstr).to   eq("")
    expect(@block.time).to      eq(1458902575)
    expect(@block.txs.first.is_coinbase?).to eq(true)
    expect(@block.txs.first.out_tx.address).to eq(@wallet.address)
    expect(Tinycoin::Core::Wallet.valid_address?(@block.txs.first.out_tx.address)).to eq(true)
    expect(@block.txs.first.out_tx.address).not_to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VR3")
  end
end
