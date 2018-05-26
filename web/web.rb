# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

module Tinycoin::Node
  class Web < Sinatra::Base
    
    def initialize front
      @front = front
      super
    end

    get "/favicon.ico" do
    end
    
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
      content_type :json
      @front.tx_store.all_uxto_json
    end
  end
end
