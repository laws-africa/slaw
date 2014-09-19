require 'slaw/za/bylaw_nodes'

module Slaw
  # Support specifically for South Africa
  module ZA

    # Support class for generating South African bylaws
    class BylawGenerator
      Treetop.load(File.dirname(__FILE__) + "/bylaw.treetop")

      # [Treetop::Runtime::CompiledParser] compiled bylaw parser
      attr_accessor :parser

      # [Slaw::Parse::Builder] builder used by the generator
      attr_accessor :builder

      def initialize
        @parser = Slaw::ZA::BylawParser.new
        @builder = Slaw::Parse::Builder.new(parser: @parser)
        @cleanser = Slaw::Parse::Cleanser.new
      end

      # Generate a Slaw::Bylaw instance from plain text.
      #
      # @param text [String] plain text
      #
      # @return [Slaw::ByLaw] the resulting bylaw
      def generate_from_text(text)
        bylaw = Slaw::ByLaw.new
        bylaw.doc = @builder.parse_and_process_text(cleanup(text))
        bylaw
      end

      def cleanup(text)
        text = @cleanser.cleanup(text)
        text = @cleanser.reformat(text)
        text
      end
    end
  end
end
