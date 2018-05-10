module Slaw
  # Base class for generating Act documents
  class ActGenerator
    # [Treetop::Runtime::CompiledParser] compiled parser
    attr_accessor :parser

    # [Slaw::Parse::Builder] builder used by the generator
    attr_accessor :builder

    # The type that will hold the generated document
    attr_accessor :document_class

    @@parsers = {}

    def initialize(grammar)
      @grammar = grammar

      @parser = build_parser
      @builder = Slaw::Parse::Builder.new(parser: @parser)
      @parser = @builder.parser
      @cleanser = Slaw::Parse::Cleanser.new
      @document_class = Slaw::Act
    end

    def build_parser
      unless @@parsers[@grammar]
        # load the grammar
        grammar_file = File.dirname(__FILE__) + "/grammars/#{@grammar}/act.treetop"
        Treetop.load(grammar_file)

        grammar_class = "Slaw::Grammars::#{@grammar.upcase}::ActParser"
        @@parsers[@grammar] = eval(grammar_class)
      end

      @parser = @@parsers[@grammar].new
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

    # Run basic cleanup on text, such as ensuring clean newlines
    # and removing tabs. This is always automatically done before
    # processing.
    def cleanup(text)
      @cleanser.cleanup(text)
    end

    # Reformat some common errors in text to help make parsing more
    # successful. Option and only recommended when processing a document
    # for the first time.
    def reformat(text)
      @cleanser.reformat(text)
    end

    # Try to determine if section numbers come after titles,
    # rather than before.
    #
    # eg:
    #
    #   Section title
    #   1. Section content
    #
    # versus
    #
    #   1. Section title
    #   Section content
    def guess_section_number_after_title(text)
      before = text.scan(/^\w{4,}[^\n]+\n\d+\. /).length
      after  = text.scan(/^\s*\n\d+\. \w{4,}/).length

      before > after * 1.25
    end

    # Transform an Akoma Ntoso XML document back into a plain-text version
    # suitable for re-parsing back into XML with no loss of structure.
    def text_from_act(doc)
      xslt = Nokogiri::XSLT(File.read(File.join([File.dirname(__FILE__), "grammars/#{@grammar}/act_text.xsl"])))
      xslt.transform(doc).child.to_xml
    end
  end
end
