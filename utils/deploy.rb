#!/usr/bin/env ruby

require 'pty'
require 'expect'
require 'yaml'

USER   = "kazushi"
PASS   = "TheXYA"
CONFIG = "../config.yml"
TARGET_PATH = "/home/kazushi/tinycoin"

module SafePty
  def self.spawn command, &block
    PTY.spawn(command) do |r,w,p|
      begin
        yield r, w, p
      rescue Errno::EIO
      ensure
        Process.wait p
      end
    end
    $?.exitstatus
  end
end

data = File.open(CONFIG) {|file|
  YAML.load(file)
}

data["networks"].each_with_index {|node, i|
  ip   = node["ip"]
  port = node["port"]
  cmd = "scp ../* #{USER}@#{ip}:#{TARGET_PATH}/"
  exit_status = SafePty.spawn(cmd) do |r, w, pid|
    # r.expect(/yes\/no/, 10) {
    #   w.puts 'yes'
    # }p
    r.expect(/^\w+/, 10){
      w.puts PASS
    }
    until r.eof? do
      puts r.readline
    end
  end
}

data["networks"].each_with_index {|node, i|
  ip   = node["ip"]
  port = node["port"]
  cmd = "scp -r ../* #{USER}@#{ip}:#{TARGET_PATH}/"
  exit_status = SafePty.spawn(cmd) do |r, w, pid|
    # r.expect(/yes\/no/, 10) {
    #   w.puts 'yes'
    # }p
    r.expect(/^\w+/, 10){
      w.puts PASS
    }
    until r.eof? do
      puts r.readline
    end
  end
}
