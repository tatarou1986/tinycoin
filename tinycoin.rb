require 'bundler/setup'
Bundler.require

module Tinycoin
  autoload :Errors, "./errors.rb"
  autoload :Node, "./node.rb"
  autoload :Core, "./blockchain.rb"
  autoload :Types, "./block.rb"
  autoload :Logger, "./logger.rb"
  autoload :Miner, "./miner.rb"

  def self.create(config_path)
    main = Node::Main.new(config_path)
    main.start
  end
end

Tinycoin::create(Dir.pwd + "/config.yml")
