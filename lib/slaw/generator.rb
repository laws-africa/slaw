module Slaw
  # Base class for generating Act documents
  class ActGenerator
    Treetop.load(File.dirname(__FILE__) + "/za/act.treetop")

    # [Treetop::Runtime::CompiledParser] compiled parser
    attr_accessor :parser

    # [Slaw::Parse::Builder] builder used by the generator
    attr_accessor :builder

    def initialize
      @parser = Slaw::ZA::ActParser.new
      @builder = Slaw::Parse::Builder.new(parser: @parser)
      @cleanser = Slaw::Parse::Cleanser.new
      @document_class = Slaw::Act
    end

    # Generate a Slaw::Act instance from plain text.
    #
    # @param text [String] plain text
    #
    # @return [Slaw::Act] the resulting act
    def generate_from_text(text)
      act = @document_class.new
      act.doc = @builder.parse_and_process_text(cleanup(text))
      act
    end

    def cleanup(text)
      text = @cleanser.cleanup(text)
      text = @cleanser.reformat(text)
      text
    end
  end
end
