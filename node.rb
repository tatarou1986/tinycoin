# -*- Coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'yaml'
require 'socket'
require 'json'

MAGICK_STRING = "!tinychain"
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
    attr_accessor :height
    attr_accessor :highest_hash
    
    def to_s
      "ip: #{sockaddr[0]}, port: #{sockaddr[1]}"
    end

    def to_hash
      {ip: @sockaddr[0], port: @sockaddr[1]}.to_hash
    end

    def initialize(ip, port)
      @sockaddr = [ip, port]
    end
  end

  class ConnectionHandler < EM::Connection
    attr_accessor :info
    attr_accessor :connected
    attr_accessor :connections
    attr_reader :type
    
    private :connections

    def log
      @log ||= Tinycoin::Logger.create("connection")
      @log
    end

    def to_s; "#{info}, #{connected?}, #{type}"; end
    def out?; @type == :out; end
    def connected?; !!@connected; end
    def connection_completed; @connected = true; end

    def initialize(info, connections, type)
      @info = info
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
      { command: command.to_s, sender: info.to_hash }.merge(args).to_json
    end
    
    def post_init
      EM.schedule {
        dir = out? ? "outgoing" : "incoming"
        log.debug { "#{dir} #{@info}" }
        @connections << self
      }
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
      case json["command"]
      when 'ping'
        # 誰かからPingが来た
        @info.height       = json["height"]
        @info.highest_hash = json["highest_hash"]
        log.debug { "receive ping #{@info.height}: #{@info.highest_hash}" }
      when 'pong'
        # (自分が打ったであろう) pingの返答が来た
        log.debug { "receive pong" }
        @connections.find()
      when 'request_block'
        # ブロックを取る
        log.debug { "receive request_block" }
      when 'block'
        # ブロックが送られてきた場合
      when 'transactions'
        log.debug { "receive transactions" }
        # トランザクション
      else
        # わけのわからんコマンド送ってくんな!
        log.warn { "unknown command: #{json.command}" }
      end
    end

    ##
    ## 
    ##
    def send_ping
      log.debug { "ping -> #{self}" }
      json = make_command_to_json("ping", height: 10, highest_hash: "0xfffffffffffff")
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def send_pong
    end

    def send_request_block(height)
      log.debug { "request_block -> #{self}" }
      json = make_command_to_json("request_block", height: height)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def send_transaction(tx)
      log.debug { "transactions -> #{self}" }
      json = make_command_to_json("transactions", tx: tx.to_hash)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)
    end

    def unbind
      @connections.delete(self)
    end
  end

  class Main
    EVENT_INTERVAL = 1
    PORT = 9999

    attr_accessor :networks    # configに記載されている他のノードへの接続情報（自分自身を除く）
    attr_accessor :height
    attr_accessor :timer
    attr_accessor :connections # 自分が接続している他のノードへのハンドラ一覧
    
    def log
      @log ||= Tinycoin::Logger.create("main")
      @log
    end

    def initialize config_path
      @timer = nil
      @connections = []
      @height = 0
      @networks = []

      log.debug { "loading networks..."  }
      read_config(config_path)
    end

    def get_ip if_name
      Socket.getifaddrs.select{|x|
        x.name == if_name and x.addr.ipv4?
      }.first.addr.ip_address
    end

    def read_config config_path
      data = File.open(config_path, 'r') {|f|
        YAML.load(f)
      }
      addrs = Socket.getifaddrs # 自分のipアドレス一覧を得る
      data["networks"].each_with_index {|node, i|
        ip   = node["ip"]
        port = node["port"].to_i
        unless get_ip("eth0") == ip
          log.debug { "#{i}. add node #{ip}:#{port}" }
          @networks << {ip: ip, port: port}
        end
      }
    end

    def start_timer
      @timer = EM.add_periodic_timer(EVENT_INTERVAL, method("main_loop"))
    end

    ## メインループ
    def main_loop
      ## 1. 他のノードが自分より大きなHeightをもっているかチェックする
      @connections.select{|conn| conn.out? }.each{|node|
        ## TODO エラー処理
        ## 接続が断たれた場合の処理。多分例外処理？
        ## if @height < node.height
        ## この場合、自分が知らない新しいブロックをもってそうなので取得してみる
        ##  send_data(data)
        ##end
        ## log.debug { "aaaaaaaaaaaaaaaaaa" }
        node.send_ping
      }

      ## 上のsend_helloを送り終わった時点で、おそらく相手がもっているheightが最新に更新されているはず
      
      ## 2. 他のノードに自分のheight以上のブロックをもっているかどうか問い合わせる
      @connections.select{|conn| conn.out? }.each{|node|
        data = Packet.new()
        ##        send_data(data)
      }
    end

    # もし、コネクションが外れていたら、自動的に再接続する
    def connect_to_others
      @networks.each{|net|
        ip   = net[:ip]
        port = net[:port].to_i
        unless @connections.any? {|conn| conn.info.sockaddr[0] == ip && conn.info.sockaddr[1] == port }
          # コネクションがまだ存在していない場合
          log.info { "connecting to #{net}" }
          EM.connect(ip, port.to_i, ConnectionHandler, NodeInfo.new(ip, port), @connections, :out)
        end
      }
    end

    def start
      EM.run do
        start_timer()
        log.info { "server start" }
        trap("INT") { EM.stop }
        EM.start_server("0.0.0.0", PORT, ConnectionHandler, NodeInfo.new("0.0.0.0", PORT), @connections, :in)

        EM.add_periodic_timer(1) do
          connect_to_others
        end
        
      end
    end
  end

end

