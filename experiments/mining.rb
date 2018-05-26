require 'bindata'
require 'digest/sha2'
require 'benchmark'

class TestBlock < BinData::Record
  endian :little
  uint32 :nonce
  stringz :msg
end

def mining_for_hello
  found = nil
  nonce = 0
  t = "0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff".to_i(16)
  
  until found
    $stdout.print sprintf("trying... %d \r", nonce)
    d = TestBlock.new(nonce: nonce, msg: "hello")
    h = Digest::SHA256.hexdigest(d.to_binary_s).to_i(16)
    
    if h <= t
      found = [h.to_s(16).rjust(64, '0'), nonce]
      break
    end
    nonce += 1
  end

  if found
    $stdout.print "Found!, #{found[0]}, nonce: #{found[1]}\n"
  end
end

mining_for_hello
