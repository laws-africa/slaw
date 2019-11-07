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

      # Grammars can override this method to run post-processing on the resulting
      # XML document.
      #
      # @param doc [Nokogiri::XML::Document]
      # @return [Nokogiri::XML::Document]
      def postprocess(doc)
      end
    end
  end
end
