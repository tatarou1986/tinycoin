# -*- Coding: utf-8 -*-
require 'bundler/setup'
Bundler.require

require 'yaml'
require 'socket'
require 'json'
require 'sinatra/base'
require 'thin'

MAGICK_STRING = "!$tinycoin"
VERSION_NUM   = 1

module Tinycoin::Node
  # webのインタフェイス
  autoload :Web, "./web/web.rb"
  
  autoload :Main, "./main.rb"
  
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
    attr_accessor :latest_rpc_time

    def initialize(ip, port) 
      @sockaddr = [ip, port]
      @latest_rpc_time = Time.now
    end

    def update_time!
      @latest_rpc_time = Time.now
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
        @info.update_time!
        log.debug { "RPC[from #{sender}], info(#{@info}), type: #{@type}, receive (ping) <--" }
        
        send_pong
      when 'pong'
        body = json["body"]
        # (自分が打ったであろう) pingの返答が来た
        @info.best_height       = body["best_height"]
        @info.best_block_hash   = body["best_block_hash"]
        @info.update_time!
        
        log.debug { "RPC[from#{sender}], info(#{@info}), type: #{@type}, receive (pong) bestHeight: #{@info.best_height}, bestBlockHash: #{@info.best_block_hash} <--" }
        
      when 'request_block' 
        # 相手から、ブロックがほしいと言われた
        body = json["body"]
        height = body["height"].to_i
        log.debug { "RPC[from#{sender}], info(#{@info}), type: #{@type}, receive (request_block[#{height}]) <--" }
        
        @info.update_time!
        
        block = @front.blockchain.find_block_by_height(height.to_i)
        if block
          # blockを持っている. 複数ある場合はどれか一つを選ばないといけない。先頭を選ぶ
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
          @front.blockchain.maybe_append_block_from_json(body.to_json)
          best_block = @front.blockchain.best_block
          log.info { "\e[32m Block(#{height}, #{hash}) additional success \e[0m, current bestBlock: Block(#{best_block.height}, #{best_block.to_sha256hash_s})" }
          
          @info.update_time!
          
          # マイナーにキャンセルを通知して、次のブロックの採掘に移行させる
          @front.miner.cancel!
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

      @info.update_time!
    end

    def send_pong
      log.debug { "RPC[to#{self}] pong -->" }
      best_block = @front.blockchain.best_block
      json = make_command_to_json("pong", best_height: best_block.height.to_i, best_block_hash: best_block.to_sha256hash_s.to_s)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)

      @info.update_time!
    end

    def send_request_block(height)
      best_block = @front.blockchain.best_block
      request_block_height = best_block.height + 1
      log.debug { "RPC[to#{self}] request_block(#{request_block_height}) -->" }
      begin
        json = make_command_to_json("request_block", height: request_block_height)
        pkt = make_packet(json)
        send_data(pkt.to_binary_s)

        @info.update_time!
      rescue => e
        log.error { "send_request_block error: #{e}\n#{e.backtrace.join("\n")}" }
        return false
      end

      return true
    end

    def send_block(block)
      hash   = block.to_sha256hash_s
      height = block.height
      log.debug { "RPC[to#{self}] block(#{height}, #{hash}) -->" }
      json = make_command_to_json("block", block.to_hash)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)

      @info.update_time!
    end

    def send_transaction(tx)
      log.debug { "RPC[to#{self}] transactions -->" }
      json = make_command_to_json("transactions", tx: tx.to_hash)
      pkt = make_packet(json)
      send_data(pkt.to_binary_s)

      @info.update_time!
    end

    def unbind
      @connections.delete(self)
    end
  end
end
