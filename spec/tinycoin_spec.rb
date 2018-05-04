# -*- coding: utf-8 -*-
require 'spec_helper'

describe Tinycoin do
#   context "when a connection handler has been given" do
#     it 'should generate a packet as json' do
#       node = Tinycoin::Node::NodeInfo.new("0.0.0.0", 9999)
#       connections = []
#       conn = Tinycoin::Node::ConnectionHandler.new(node, connections, nil)
#       expected_json_str=<<JSON
# {"type":"block","height":0,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","nonce":8826,"bits":520093695,"time":1461025176,"jsonstr":""}
# JSON
#       json = conn.make_command_to_json("ping", height: 10, highest_hash: "0xfffffffffffff")
#       expect(json).to eq(expected_json_str)
#     end
#   end
  
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
{"type":"block","height":0,"prev_hash":"0000000000000000000000000000000000000000000000000000000000000000","hash":"#{g.to_sha256hash_s}","nonce":8826,"bits":520093695,"time":1461025176,"txs":[],"jsonstr":""}
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
        block = Tinycoin::Core::Block.new_block("0000000000000000000000000000000000000000000000000000000000000000", 8826, 520093695, 1461025176, 0, "")
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
        orig_block = Tinycoin::Core::Block.new_block(prev_hash = "0000000000000000000000000000000000000000000000000000000000000000", 
                                                     nonce     = 1264943, 
                                                     bits      = 26229296,
                                                     time      = 1458902575, 
                                                     height    = 0, 
                                                     payloadstr = "")
        orig_block_hash_str = orig_block.to_sha256hash_s

        @wallet = Tinycoin::Core::Wallet.new  
        @wallet.generate_key_pair
        
        @hash = []
        @hash[0] = "0000000000000000000000000000000000000000000000000000000000000000"
        @block = Tinycoin::Core::BlockBuilder.make_block_as_miner(
              @wallet,
              @hash[0],
              1264943,
              26229296,
              1458902575,
              0
        )
        jsonstr=<<JSON
{ 
  "type": "block",
  "height": 0,
  "prev_hash": "0000000000000000000000000000000000000000000000000000000000000000",
  "hash": "#{orig_block_hash_str}",
  "nonce": 1264943,
  "bits": 26229296,
  "time": 1458902575,
  "txs" :[{"txid" : "1596d82958b4b5474565627bc40dd23f48aa50a375ba06b25e4b8ad953105f51",
           "vin"  :{"type": "coinbase",
                    "scriptSig" : {"asm": "OP_NOP"}},
           "vout" :{"type"  : "coinbase",
                    "value" : 1,
                    "scriptPubKey" :{"asm": "OP_PUSH true", "address": "moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe" }}
          }],
  "jsonstr": ""
}
JSON
        test_block = Tinycoin::Core::Block.parse_json(jsonstr)
        expect(test_block.prev_hash).to eq(0)
        expect(test_block.height).to eq(0)
        expect(test_block.nonce).to eq(1264943)
        expect(test_block.time).to eq(1458902575)
        expect(test_block.bits).to eq(26229296)
        expect(test_block.jsonstr).to eq("")
        expect(test_block.to_sha256hash_s).to eq(orig_block_hash_str)

        expect(test_block.txs.size).to eq(1)
        expect(test_block.txs.first.is_coinbase?).to eq(true)
        expect(test_block.txs.first.out_tx.address).to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VRe")
        expect(@wallet.valid_address?(test_block.txs.first.out_tx.address)).to eq(true)
        expect(test_block.txs.first.out_tx.address).not_to eq("moDu6EtnGGpcTEkNZRJbytr9rJA4H49VR3")
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

  describe "BlockChain" do
    before :each do
      @hash = []     
      @hash[0] = "0000000000000000000000000000000000000000000000000000000000000000"
      @hash[1] = "0000000000000000000000000000000000000000000000000000000000000001"
      @hash[2] = "0000000000000000000000000000000000000000000000000000000000000002"
      @hash[3] = "0000000000000000000000000000000000000000000000000000000000000003"
      @hash[4] = "0000000000000000000000000000000000000000000000000000000000000004"
      @hash[5] = "0000000000000000000000000000000000000000000000000000000000000005"
      @hash[6] = "0000000000000000000000000000000000000000000000000000000000000006"
      @hash[7] = "0000000000000000000000000000000000000000000000000000000000000007"
      @hash[8] = "0000000000000000000000000000000000000000000000000000000000000008"
      @hash[9] = "0000000000000000000000000000000000000000000000000000000000000009"
      @hash[10] = "0000000000000000000000000000000000000000000000000000000000000010"
      
      
      @genesis_block = Tinycoin::TestBlock.new(@hash[0], @hash[1])
      @blockchain = Tinycoin::Core::BlockChain.new(@genesis_block)
    end

    context "when blocks has been given" do
      describe "#add_block" do
        it 'should add blocks' do
          block = Tinycoin::TestBlock.new(@hash[1], @hash[2])
          expect(@blockchain.add_block(@hash[1], block)).to eq(block)

          block = Tinycoin::TestBlock.new(@hash[2], @hash[3])
          expect(@blockchain.add_block(@hash[2], block)).to eq(block)

          block = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          expect(@blockchain.add_block(@hash[3], block)).to eq(block)
        end
      end

      describe "#find_block_by_hash" do
        it 'should find out a block' do
          block1 = Tinycoin::TestBlock.new(@hash[1], @hash[2])
          @blockchain.add_block(@hash[1], block1)
          block2 = Tinycoin::TestBlock.new(@hash[2], @hash[3])
          @blockchain.add_block(@hash[2], block2)
          block3 = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          @blockchain.add_block(@hash[3], block3)
          
          ret = @blockchain.find_winner_block_head()
          expect(ret.to_sha256hash_s).to eq(@hash[4])
        end
      end
      

      describe "#find_block_by_height" do
        it 'should find out a block' do
          block1 = Tinycoin::TestBlock.new(@hash[1], @hash[2], 2)
          @blockchain.add_block(@hash[1], block1)
          block2 = Tinycoin::TestBlock.new(@hash[2], @hash[3], 3)
          @blockchain.add_block(@hash[2], block2)
          block3 = Tinycoin::TestBlock.new(@hash[3], @hash[4], 4)
          @blockchain.add_block(@hash[3], block3)
          
          ret = @blockchain.find_block_by_height(1)
          expect(ret.first.to_sha256hash_s).to eq(@hash[1])

          ret = @blockchain.find_block_by_height(2)
          expect(ret.first.to_sha256hash_s).to eq(@hash[2])

          ret = @blockchain.find_block_by_height(3)
          expect(ret.first.to_sha256hash_s).to eq(@hash[3])

          ret = @blockchain.find_block_by_height(4)
          expect(ret.first.to_sha256hash_s).to eq(@hash[4])
        end
      end
    end

    context "when blockchain has branches" do
      describe "#find_winner_block_head" do
        it 'should find out the winner block' do
          block = Tinycoin::TestBlock.new(@hash[1], @hash[2])
          @blockchain.add_block(@hash[1], block)
          block = Tinycoin::TestBlock.new(@hash[2], @hash[3])
          @blockchain.add_block(@hash[2], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          @blockchain.add_block(@hash[3], block)

          ##
          ## branch at the block 3
          ##
          block = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          @blockchain.add_block(@hash[3], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[5])
          @blockchain.add_block(@hash[3], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[6])
          @blockchain.add_block(@hash[3], block)

          ##
          ## Winner!
          ##
          block = Tinycoin::TestBlock.new(@hash[6], @hash[7])
          @blockchain.add_block(@hash[6], block)
          block = Tinycoin::TestBlock.new(@hash[7], @hash[8])
          @blockchain.add_block(@hash[7], block)

          ret = @blockchain.find_winner_block_head()
          expect(ret.to_sha256hash_s).to eq(@hash[8])
        end
      end

      describe "#find_block_by_hash" do
        it 'should find out the block' do
          
          block = Tinycoin::TestBlock.new(@hash[1], @hash[2])
          @blockchain.add_block(@hash[1], block)
          block = Tinycoin::TestBlock.new(@hash[2], @hash[3])
          @blockchain.add_block(@hash[2], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          @blockchain.add_block(@hash[3], block)

          ##
          ## branch at the block 3
          ##
          block = Tinycoin::TestBlock.new(@hash[3], @hash[4])
          @blockchain.add_block(@hash[3], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[5])
          @blockchain.add_block(@hash[3], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[6])
          @blockchain.add_block(@hash[3], block)

          ##
          ## Winner!
          ##
          block = Tinycoin::TestBlock.new(@hash[6], @hash[7])
          @blockchain.add_block(@hash[6], block)
          block = Tinycoin::TestBlock.new(@hash[7], @hash[8])
          @blockchain.add_block(@hash[7], block)

          ret = @blockchain.find_block_by_hash(@hash[6])
          expect(ret.to_sha256hash_s).to eq(@hash[6])          
          
        end
      end

      describe "#find_block_by_height" do
        it 'should find out a block' do
          block = Tinycoin::TestBlock.new(@hash[1], @hash[2], 2)
          @blockchain.add_block(@hash[1], block)
          block = Tinycoin::TestBlock.new(@hash[2], @hash[3], 3)
          @blockchain.add_block(@hash[2], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[4], 4)
          @blockchain.add_block(@hash[3], block)

          ##
          ## branch at the block 3
          ##
          block = Tinycoin::TestBlock.new(@hash[3], @hash[5], 4)
          @blockchain.add_block(@hash[3], block)
          block = Tinycoin::TestBlock.new(@hash[3], @hash[6], 4)
          @blockchain.add_block(@hash[3], block)

          ##
          ## Winner!
          ##
          block = Tinycoin::TestBlock.new(@hash[6], @hash[7], 5)
          @blockchain.add_block(@hash[6], block)
          block = Tinycoin::TestBlock.new(@hash[7], @hash[8], 6)
          @blockchain.add_block(@hash[7], block)

          ret = @blockchain.find_block_by_height(2)
          expect(ret.first.to_sha256hash_s).to eq(@hash[2])

          ret = @blockchain.find_block_by_height(3)
          expect(ret.first.to_sha256hash_s).to eq(@hash[3])

          ret = @blockchain.find_block_by_height(4)
          expect(ret.size).to eq(3)
          expect(ret[0].to_sha256hash_s).to eq(@hash[4])
          expect(ret[1].to_sha256hash_s).to eq(@hash[5])
          expect(ret[2].to_sha256hash_s).to eq(@hash[6])

          ret = @blockchain.find_block_by_height(5)
          expect(ret.first.to_sha256hash_s).to eq(@hash[7])
          
          ret = @blockchain.find_block_by_height(6)
          expect(ret.first.to_sha256hash_s).to eq(@hash[8])

          ## 見つからない
          ret = @blockchain.find_block_by_height(7)
          expect(ret).to eq(nil)

          ## 見つからない
          ret = @blockchain.find_block_by_height(9)
          expect(ret).to eq(nil)
        end
      end
    end

    context "when blockchain has branches" do
      describe "#find_winner_block_head" do
        it 'should find out the winner block' do
          ret = Tinycoin::Core::BlockChain.get_target(0x1effffff)
          expect(ret.first).to eq("0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
        end
      end
    end
    
  end
end

