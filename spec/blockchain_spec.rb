# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Tinycoin::Core::BlockChain" do
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
