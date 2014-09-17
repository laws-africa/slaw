module Slaw
  module Parse
    class ParseError < Exception
      attr_accessor :line, :column

      def initialize(message, opts)
        super(message)

        self.line = opts[:line]
        self.column = opts[:column]
      end

      # TODO: move this elsewhere, it's out of context here
      def to_json(g=nil)
        msg = self.message
        msg = msg[0..200] + '...' if msg.length > 200

        {
          message: msg,
          line: self.line,
          column: self.column,
        }.to_json(g)
      end
    end
  end
end
