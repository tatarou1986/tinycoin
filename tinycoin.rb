require 'bundler/setup'
Bundler.require

module Tinycoin
  autoload :Errors, "./errors.rb"
  autoload :Node, "./node.rb"
  autoload :Core, "./blockchain.rb"
  autoload :Types, "./types.rb"
  autoload :Logger, "./logger.rb"
  autoload :Miner, "./miner.rb"

  def self.create(config_path)
    main = Node::Main.new(config_path)
    main.start
  end

  def self.do_genesis_mining
    log = Tinycoin::Logger.create("connection")
    Tinycoin::Miner.do_genesis_mining(log)
  end
end

if ARGV.size > 0
  if ARGV[0] == "g"
    Tinycoin::do_genesis_mining
    exit(0)
  end
else
  Tinycoin::create(Dir.pwd + "/config.yml")
end
