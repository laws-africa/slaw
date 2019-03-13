require 'polyglot'
require 'treetop'

module Slaw
  # Base class for generating Act documents
  class ActGenerator
    # [Treetop::Runtime::CompiledParser] compiled parser
    attr_accessor :parser

    # [Slaw::Parse::Builder] builder used by the generator
    attr_accessor :builder

    @@parsers = {}

    def initialize(grammar)
      @grammar = grammar

      @parser = build_parser
      @builder = Slaw::Parse::Builder.new(parser: @parser)
      @parser = @builder.parser
      @cleanser = Slaw::Parse::Cleanser.new
    end

    def build_parser
      unless @@parsers[@grammar]
        # load the grammar with polyglot and treetop
        # this will ensure the class below is available
        # see: http://cjheath.github.io/treetop/using_in_ruby.html
        require "slaw/grammars/#{@grammar}/act"
        grammar_class = "Slaw::Grammars::#{@grammar.upcase}::ActParser"
        @@parsers[@grammar] = eval(grammar_class)
      end

      @parser = @@parsers[@grammar].new
    end

    # Generate a Slaw::Act instance from plain text.
    #
    # @param text [String] plain text
    #
    # @return [Nokogiri::Document] the resulting xml
    def generate_from_text(text)
      @builder.parse_and_process_text(cleanup(text))
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
      # look on the load path for an XSL file for this grammar
      filename = "/slaw/grammars/#{@grammar}/act_text.xsl"

      if dir = $LOAD_PATH.find { |p| File.exist?(p + filename) }
        xslt = Nokogiri::XSLT(File.read(dir + filename))
        xslt.transform(doc).child.to_xml
      else
        raise "Unable to find text XSL for grammar #{@grammar}: #{fragment}"
      end
    end
  end
end
