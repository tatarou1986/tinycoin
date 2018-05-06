# -*- coding: utf-8 -*-
module Tinycoin::Node
  class Main
    TIMERS_INTERVAL = {
      ping: 1,
      request_block: 0.5,
      connect: 5
    }
    
    MINING_START_INTERVAL = 3 # 起動してからマイニングが開始されるまでの待機時間 (秒)
    PORT       = 9999
    WEB_PORT   = 8080
    WEB_SERVER = 'thin'
    WEB_HOST   = '0.0.0.0'
    
    attr_accessor :height
    attr_accessor :connections # 自分が接続している他のノードへのハンドラ一覧
    attr_reader :blockchain
    attr_reader :tx_pool
    attr_reader :miner
    attr_reader :self_info
    
    def log
      @log ||= Tinycoin::Logger.create("main")
      @log
    end

    def initialize config_path
      @networks = []  # configに記載されている他のノードへの接続情報（自分自身を除く）
      @timers = {}
      
      @connections = []

      @self_info = nil
      @tx_pool = nil
      
      # 自分のウォレット
      @wallet = Tinycoin::Core::Wallet.new
      @wallet.generate_key_pair
      
      # blockchain周り。genesis (創始) blockや、blockchainを表すclassなど
      @genesis    = Tinycoin::Core::Block.new_genesis
      @blockchain = Tinycoin::Core::BlockChain.new(@genesis, self)
      @miner      = Tinycoin::Miner.new(@genesis, @blockchain, @tx_pool, @wallet) # TODO: tx_poolがnilなので実装しないと
      
      @mining_start_time = nil

      log.debug { "loading networks..."  }
      read_config(config_path)
    end

    def get_ip if_name
      # ipv4にしか対応していない
      Socket.getifaddrs.select{|x|
        x.name == if_name and x.addr.ipv4?
      }.first.addr.ip_address
    end

    def read_config config_path
      data = File.open(config_path, 'r') {|f|
        YAML.load(f)
      }
      data["networks"].each_with_index {|node, i|
        ip   = node["ip"]
        port = node["port"].to_i
        if get_ip("eth0") == ip
          @self_info = NodeInfo.new(ip, port)
        else
          log.debug { "#{i}. add node #{ip}:#{port}" }
          @networks << {ip: ip, port: port}
        end
      }
    end
    
    def try_add_block_from_other(new_block)
      
    end

    def stop_timers
      @timers.each {|n, t| EM.cancel_timer t }
    end

    def start_timers
      [:ping, :request_block, :connect].each do |name|
        @timers[name] = EM.add_periodic_timer(TIMERS_INTERVAL[name], method("worker_#{name}"))
      end
    end

    # 定期的にpingを送る
    def worker_ping force = false
      ## 1. 他のノードが自分より大きなHeightをもっているかチェックする
      @connections.shuffle.select{ |conn| conn.out? }.each{|node|
        if force
          node.send_ping
        else
          # 有効なRPCを受けてもいない、送ってもいない状態が5秒以上続いたらpingを送る
          if (Time.now - node.info.latest_rpc_time) > 5
            node.send_ping
            node.info.set_idle!
          end
        end
      }
    end

    def worker_request_block
      best_block = @blockchain.best_block
      @connections.shuffle.select {|conn|
        conn.out? && best_block.height < conn.info.best_height }.each{|node|
        # TODO: ここで、heightは違うけどハッシュが異なる場合
        # つまり、blockchainが分岐してしまっている場合は、そのブランチを取りに行かないといけない
        if node.info.should_send?
          log.debug {
            "\e[35m Found higher block(#{node.info.best_height}, " +
            "#{node.info.best_block_hash})\e[0m at Node(#{node.info})"
          }
          # リクエストは一人に送れればいいので、成功したらループを抜ける
          if node.send_request_block(best_block.height + 1)
            return
          end
        end
      }      
    end

    # 定期的に接続状態をチェックして、必要なら再接続
    def worker_connect
      # 接続が絶たれる可能性や、タイミング問題（つなぎに行ったけど、接続先のサーバがまだ立ち上がってない）
      # などがあるので、タイマーで定期的に接続状態をチェックして、接続が確立していなければ再接続を促すようにする
      connect_to_others
    end
    
    def connect_to_others
      @networks.each{|net|
        ip   = net[:ip]
        port = net[:port].to_i
        unless @connections.any? {|conn| conn.info.sockaddr[0] == ip && conn.info.sockaddr[1] == port }
          # コネクションがまだ存在していない場合のみ接続を試みる
          log.debug { "trying to connecting #{net} ... " }
          EM.connect(ip, port.to_i, ConnectionHandler, NodeInfo.new(ip, port), @connections, :out, self)
        end
      }
    end

    def start_web_server web
      @web_dispatch = Rack::Builder.app do
        map '/' do
          run web
        end
      end

      h = {
        app:     @web_dispatch,
        server:  WEB_SERVER,
        Host:    WEB_HOST,
        Port:    WEB_PORT,
        signals: false,
      }

      Rack::Server.start(h)
    end

    def start
      EM.run do
        start_timers
        log.info { "server start" }
        trap("INT") { stop_timers; EM.stop }
        # serverを立ち上げる
        EM.start_server("0.0.0.0", PORT, ConnectionHandler, NodeInfo.new("0.0.0.0", PORT), @connections, :in, self)

        @web = Tinycoin::Node::Web.new

        # Webサーバを立ち上げる
        EM.defer do
          start_web_server @web
        end

        # 起動時は、全員に対して強制的にpingを送る
        EM.schedule {
          worker_ping(true)
        }
        
        # マイナー（採掘器）を起動
        EM.add_timer(MINING_START_INTERVAL) do
          unless @mining_start_time
            @mining_start_time = Time.now
            log.info { "start mining at: #{@mining_start_time} " }
          end
          
          # 別スレッドでマイニング開始
          EM.defer do
            loop do
              found = @miner.do_mining
              unless found
                log.info { "\e[31m Canceled mining. Restart miner with new height \e[0m" }
              end
              # TODO: nonceを使い果たした場合はBlockに含める時刻をずらしてnonce: 0からやり直す
            end
          end 
        end
        
      end
    end
  end
end
