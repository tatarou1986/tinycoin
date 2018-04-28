# -*- Coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'yaml'
require 'socket'
require 'json'

MAGICK_STRING = "!$tinycoin"
VERSION_NUM   = 1

module Tinycoin::Node
  class Packet < BinData::Record
    endian :little
    string :magic, :length => MAGICK_STRING.length()
    uint32 :version
    uint32 :json_length
    string :json, :read_length => :json_length
  end

  class NodeInfo
    attr_reader :sockaddr
    attr_accessor :best_height
    attr_accessor :best_block_hash

    def initialize(ip, port) 
      @sockaddr = [ip, port]
    end
    
    def to_s; "#{sockaddr[0]}:#{sockaddr[1]}"; end
    def to_hash; {ip: @sockaddr[0], port: @sockaddr[1]}.to_hash; end
    def get_ip; @sockaddr[0]; end
  end

  class ConnectionHandler < EM::Connection
    attr_accessor :connected
    attr_accessor :connections
    attr_reader :type
    attr_reader :info
    
    private :connections

    def log
      @log ||= Tinycoin::Logger.create("connection")
      @log
    end

    def to_s; "#{info}, connected: #{connected?}, type: #{type}"; end
    def out?; @type == :out; end
    def connected?; !!@connected; end
    
    def connection_completed
      log.info { "established connection to #{@info}" }
      @connections << self
      @connected = true
    end

    def initialize(info, connections, type, front)
      @front = front
      @info = info
      @info.best_height     = front.blockchain.best_block.height.to_i
      @info.best_block_hash = front.blockchain.best_block.to_sha256hash_s
      @connections = connections
      @type = type
    end

    def make_packet(json)
      Packet.new(magic: MAGICK_STRING,
                 version: VERSION_NUM,
                 json_length: json.size,
                 json: json)
    end

    def make_command_to_json(command, **args)
      { command: command.to_s, sender: @front.self_info.get_ip, body: args }.to_json
    end

    def validate_packet(data)
      pkt = Packet.read(data)
      if pkt.magic == MAGICK_STRING && 
          pkt.version == VERSION_NUM
        return JSON.parse(pkt.json)
      else
        raise InvalidPacketError
      end
    end

    def receive_data(data)
      json = validate_packet(data)      
      sender = json["sender"]
      case json["command"]
      when 'ping'
        # 誰かからPingが来た
        log.debug { "RPC[from #{sender}], info(#{@info}), type: #{@type}, receive (ping) <--" }
        send_pong
      when 'pong'
        body = json["body"]
        # (自分が打ったであろう) pingの返答が来た
        @info.best_height       = body["best_height"]
        @info.best_block_hash   = body["best_block_hash"]
        log.debug { "RPC[from#{sender}], info(#{@info}), type: #{@type}, receive (pong) bestHeight: #{@info.best_height}, bestBlockHash: #{@info.best_block_hash} <--" }
        
      when 'request_block' 
        # 相手から、ブロックがほしいと言われた
        body = json["body"]
        height = body["height"].to_i
        log.debug { "RPC[from#{sender}], info(#{@info}), type: #{@type}, receive (request_block[#{height}]) <--" }
        ## TODO @blockchainから当該heightのブロックを取得して送り返す
        block = @front.blockchain.find_block_by_height(height.to_i)
        if block
          # TODO: blockを持っている. 複数ある場合はどれか一つを選ばないといけない。とりあえずを先頭を選ぶ
          send_block(block.first)
        else
          log.error { "request_block(#{height}) from #{sender}. but not exists" }
        end
        
      when 'block'
        # 相手から、ブロックが送られてきた
        body   = json["body"]
        height = body["height"]
        hash   = body["hash"]
        log.debug { "RPC[from#{sender}], info(#{@info}), type: #{@type}, receive (block[#{height}, #{hash}]) <--" }

        begin
          log.info { "\e[36m Try to append block(#{height}, #{hash}) \e[0m "}
          @front.blockchain.maybe_append_block_from_hash(body)
          best_block = @front.blockchain.best_block
          log.info { "\e[32m Block(#{height}, #{hash}) additional success \e[0m, current bestBlock: Block(#{best_block.height}, #{best_block.to_sha256hash_s})" }
        rescue => e
          log.error { "\e[31m Failed to append the received block[#{height}, #{hash}].\e[0m reason: #{e}\n #{e.backtrace.join("\n")}" }
        end
        
      when 'txs'
        log.debug { "RPC[from#{sender}] receive transactions <--" }
        # トランザクション
      else
        # わけのわからんコマンド送ってくんな!
        cmd = json["command"]
        log.error { "RPC[from#{sender}] \e[31m receive unknown command: \e[0m#{cmd} <--" }
      end
    end

    ##
    ## 
    ##
    def send_ping
      log.debug { "RPC[to#{self}] ping -->" }
      json = make_command_to_json("ping")
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def send_pong
      log.debug { "RPC[to#{self}] pong -->" }
      best_block = @front.blockchain.best_block
      json = make_command_to_json("pong", best_height: best_block.height.to_i, best_block_hash: best_block.to_sha256hash_s.to_s)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def send_request_block(height)
      best_block = @front.blockchain.best_block
      request_block_height = best_block.height + 1
      log.debug { "RPC[to#{self}] request_block(#{request_block_height}) -->" }
      ## TODO @blockchainから要求されたheightのblockを取得して送り返す
      begin
        json = make_command_to_json("request_block", height: request_block_height)
        pkt = make_packet(json)
        send_data(pkt.to_binary_s)
      rescue => e
        log.error { "send_request_block error: #{e}\n#{e.backtrace.join("\n")}" }
      end
    end

    def send_block(block)
      hash   = block.to_sha256hash_s
      height = block.height
      log.debug { "RPC[to#{self}] block(#{height}, #{hash}) -->" }
      json = make_command_to_json("block", block.to_hash)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def send_transaction(tx)
      log.debug { "RPC[to#{self}] transactions -->" }
      json = make_command_to_json("transactions", tx: tx.to_hash)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def unbind
      @connections.delete(self)
    end
  end

  class Main
    TIMERS_INTERVAL = {
      ping: 1,
      request_block: 1,
      connect: 5
    }
    
    MINING_START_INTERVAL = 3 # 起動してからマイニングが開始されるまでの待機時間 (秒)
    PORT = 9999
    
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
      
      # blockchain周り。genesis (創始) blockや、blockchainを表すclassなど
      @genesis    = Tinycoin::Core::Block.new_genesis
      @blockchain = Tinycoin::Core::BlockChain.new(@genesis)
      @miner      = Tinycoin::Miner.new(@genesis, @blockchain, @tx_pool) # TODO: tx_poolがnilなので実装しないと
      
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
    def worker_ping
      ## 1. 他のノードが自分より大きなHeightをもっているかチェックする
      @connections.shuffle.select{ |conn| conn.out? }.each{ |node| node.send_ping }
    end

    def worker_request_block
      best_block = @blockchain.best_block
      @connections.shuffle.select {|conn| conn.out? && best_block.height < conn.info.best_height }.each{|node|
        log.debug { "\e[35m Found higher block(#{node.info.best_height}, #{node.info.best_block_hash})\e[0m at Node(#{node.info})" }
        node.send_request_block(best_block.height + 1)
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

    def start
      EM.run do
        start_timers
        log.info { "server start" }
        trap("INT") { stop_timers; EM.stop }
        # serverを立ち上げる
        EM.start_server("0.0.0.0", PORT, ConnectionHandler, NodeInfo.new("0.0.0.0", PORT), @connections, :in, self)

        # マイナー（採掘器）を起動
        EM.add_timer(MINING_START_INTERVAL) do
          unless @mining_start_time
            @mining_start_time = Time.now
            log.info { "start mining at: #{@mining_start_time} " }
          end
          
          # 別スレッドでマイニング開始
          EM.defer do
            loop do
              found = @miner.do_mining()
              # TODO: nonceを使い果たした場合はBlockに含める時刻をずらしてnonce: 0からやり直す
            end
          end 
        end
        
      end
    end
  end

end
