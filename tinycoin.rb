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

  def self.find_nonce_for_tests
    log = Tinycoin::Logger.create("test")
    wallet = Tinycoin::Core::Wallet.new
    wallet.generate_key_pair

    txs = [Tinycoin::Core::TxBuilder.make_coinbase(wallet)]

    Tinycoin::Miner.do_mining_with_txs(
          log       = log,
          wallet    = wallet,
          prev_hash = "0000000000000000000000000000000000000000000000000000000000000000",
          bits      = 26229296,
          time      = Time.now,
          height    = 1,
          txs       = txs,
          payloadstr = ""
    )
  end
end

if ARGV.size > 0
  if ARGV[0] == "g"
    Tinycoin::do_genesis_mining
    exit(0)
  elsif ARGV[0] == "t"
    Tinycoin::find_nonce_for_tests
    exit(0)
  end
else
  Tinycoin::create(Dir.pwd + "/config.yml")
end
