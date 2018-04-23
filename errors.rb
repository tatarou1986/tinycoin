module Tinycoin::Errors
  class UnimplementedError < StandardError; end
  class InvalidPacketError < StandardError; end
  class InvalidUnknownFormat < StandardError; end
  class InvalidFieldFormat < StandardError; end
  class InvalidRequest < StandardError; end
  class InvalidBlock < StandardError; end
  class NoAvailableBlockFound < StandardError; end
  class ChainBranchingDetected < StandardError; end
end
