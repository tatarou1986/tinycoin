module Tinycoin::Errors
  class UnimplementedError < StandardError; end
  class InvalidPacketError < StandardError; end
  class InvalidUnknownFormat < StandardError; end
  class InvalidFieldFormat < StandardError; end
  class InvalidRequest < StandardError; end
  class InvalidBlock < StandardError; end
  class NoAvailableBlockFound < StandardError; end
  class ChainBranchingDetected < StandardError; end
  class NoSignedTx < StandardError; end
  class InvalidOpcode < StandardError; end
  class InvalidTx < StandardError; end

  class NotImplemented < StandardError; end
end
