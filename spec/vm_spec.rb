# -*- coding: utf-8 -*-
require_relative 'spec_helper.rb'

describe "Tinycoin::Core::VM" do
  it 'should execute the coinbase script' do
    @vm = Tinycoin::Core::VM.new
    in_script = Tinycoin::Core::Script.generate_coinbase_in
    parsed = Tinycoin::Core::Script.parse(in_script)

    @vm.execute!(parsed)
    expect(@vm.stack.size).to eq(0)
    expect(@vm.ret_true?).to eq(false)

    @vm = Tinycoin::Core::VM.new
    out_script = Tinycoin::Core::Script.generate_coinbase_out
    parsed = Tinycoin::Core::Script.parse(out_script)

    @vm.execute!(parsed)
    expect(@vm.stack.size).to eq(1)
    expect(@vm.ret_true?).to eq(true)
  end

  it 'should execute the opcode OP_RETURN' do
    script = "OP_RETURN"
    @vm = Tinycoin::Core::VM.new
    parsed = Tinycoin::Core::Script.parse(script)
    @vm.execute!(parsed)
    expect(@vm.stack.size).to eq(1)
    expect(@vm.ret_true?).to eq(true)
  end

  it 'should execute opcodes OP_PUSH and OP_DUP' do
    script = "OP_PUSH hello OP_DUP"
    @vm = Tinycoin::Core::VM.new
    parsed = Tinycoin::Core::Script.parse(script)
    @vm.execute!(parsed)
    expect(@vm.stack.size).to eq(2)
    expect(@vm.stack[0]).to eq("hello")
    expect(@vm.stack[1]).to eq("hello")
  end

  it 'should get invalid opcode error' do
    @vm = Tinycoin::Core::VM.new
    script = "OP_INVALID test"
    parsed = Tinycoin::Core::Script.parse(script)
    expect{ @vm.execute!(parsed) }.to raise_error(Tinycoin::Errors::InvalidOpcode)
  end
end

describe "Tinycoin::Core::Script" do
  it 'should generate a coinbase script' do
    in_script = Tinycoin::Core::Script.generate_coinbase_in
    out_script = Tinycoin::Core::Script.generate_coinbase_out
    expect(out_script).to eq("OP_PUSH true")
    expect(in_script).to eq("OP_NOP")
  end
end
