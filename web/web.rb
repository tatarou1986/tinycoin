# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

module Tinycoin::Node
  class Web < Sinatra::Base
    
    get '/' do
      @txs = []
      erb :index
    end

    # 送金処理
    get '/send' do
      raise "NOT IMPLEMENTED"
    end

    # トランザクションを全部取得
    get '/txs' do
      raise "NOT IMPLEMENTED"
    end
  end
end
