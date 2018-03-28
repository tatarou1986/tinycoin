# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

module Tinycoin
  class NodeInfo
    attr_reader :sockaddr
    attr_reader :is_self
    attr_accessor :height
    attr_accessor :block_hash

    def initialize(ip, port, is_self = false)
      @sockaddr = [ip, port]
      @is_other = !is_self # 自分自身かどうか
    end
  end

  class ConnectionHandler < EM::Connection
    attr_accessor :info

    def initialize(info, connections)
      @info = info
      @connections = connections
      post_init
    end
    
    def post_init
      EM.schedule {
        @connections << self
      }
    end

    def receive_data(data)
      case data
      when 'send_block'
        ## ブロックが送られてきた場合
      when 'send_hello'
        ## 自分の情報(自分のheightとか)
      when 'send_transactions'
        ## トランザクション
      else
        ## わけのわからんコマンド送ってくんな!
      end
    end

    def unbind
      @connections.delete(self)
    end
  end

  class TransactionStore
    def get_unsent_trans
      []
    end
  end

  class Main
    EVENT_INTERVAL = 10
    PORT = 9999
    NETWORKS = [
                {ip: "192.168.1.3", port: PORT},
                {ip: "192.168.1.4", port: PORT}
               ]

    attr_accessor :log
    attr_accessor :height
    attr_accessor :timer
    attr_accessor :connections # 自分が接続している他のノード一覧

    def initialize
      @timer = nil
      @connections = []
      @height = 0

      @log = Log4r::Logger.new(__FILE__)
      @log.outputters << Log4r::Outputter.stdout
    end

    def start_timer
      @timer = EM.add_periodic_timer(EVENT_INTERVAL, method("main_loop"))
    end

    ## メインループ
    def main_loop
      ## 1. 他のノードが自分より大きなHeightをもっているかチェックする
      @connections.select(:is_other).each{|node|
        ## TODO エラー処理
        ## 接続が断たれた場合の処理。多分例外処理？
        if @height < node.height
          ## この場合、自分が知らない新しいブロックをもってそうなので取得してみる
          data = Packet.new()
          send_data(data)
        end
      }

      ## 2. 他のノードに自分のheight以上のブロックをもっているかどうか問い合わせる
      @connections.select(:is_other).each{|node|
        data = Packet.new()
        send_data(data)
      }
    end

    def connect_to_others
      NETWORKS.each{|net|
        ip   = net[:ip]
        port = net[:port].to_i
        EM.connect(host, port.to_i, ConnectionHandler, NodeInfo.new(ip, port), @connections)
      }
    end

    def start
      EM.run do
        start_timer()
        @log.debug { "server start" }
        EM.start_server("0.0.0.0", PORT, ConnectionHandler, NodeInfo.new("0.0.0.0", PORT, true), @connections)
      end
    end
  end

end

trap("INT") { EM.stop }
main = Tinycoin::Main.new
main.start
