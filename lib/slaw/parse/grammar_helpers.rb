module Slaw
  module Parse
    # These helpers are mixed into the treetop grammar and provide a means for
    # exposing options into the grammar.
    #
    # @see Builder#parse_options
    module GrammarHelpers
      attr_writer :options

      def options
        @options ||= {}
      end
    end
  end
end
