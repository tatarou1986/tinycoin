# -*- coding: utf-8 -*-
require_relative 'spec_helper.rb'

describe "Tinycoin::Core::VM" do
  it 'should execute the coinbase script' do
    @vm = Tinycoin::Core::VM.new
    script = Tinycoin::Core::Script.generate_coinbase
    parsed = Tinycoin::Core::Script.parse(script)

    @vm.execute!(parsed)
    expect(@vm.stack.size).to eq(1)
    expect(@vm.ret_true?).to eq(true)
  end
end

describe "Tinycoin::Core::Script" do
  it 'should generate a coinbase script' do
    script = Tinycoin::Core::Script.generate_coinbase
    expect(script).to eq("OP_PUSH true")
  end
end
