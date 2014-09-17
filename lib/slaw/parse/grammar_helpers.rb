module Slaw
  module Parse
    module GrammarHelpers
      attr_writer :options

      def options
        @options ||= {}
      end
    end
  end
end
