module Tinycoin::Core
  class VM
    attr_reader :stack
    
    OP_CODES =
      [
       "OP_PUSH",
       "OP_RETURN"
      ]
    
    def initialize
      @stack = []
    end

    def execute! parsed_script
      do_execute!(@stack, parsed_script)
    end

    def ret_true?
      @stack.size == 1 && @stack[0].to_s.downcase == "true"
    end

    private
    def do_execute! stack, rest_script
      return if rest_script.empty?
      op = rest_script.first
      case op
      when /OP_(.+)$/
        rest_script = dispatch_opcode(stack, op, rest(rest_script))
      else
        raise Tinycoin::Errors::InvalidOpcode
      end
      do_execute!(stack, rest_script)
    end
    
    def dispatch_opcode stack, op, rest_script
      if OP_CODES.member?(op)
        method(op.to_s.downcase).call(stack, rest_script)
      else
        raise Tinycoin::Errors::InvalidOpcode 
      end
    end
    
    def op_push stack, rest_script
      stack << rest_script.first
      rest(rest_script)
    end

    def op_return stack, rest_script
      stack << "true"
      rest_script
    end

    def rest ary
      ary.drop(1)
    end
  end
end
