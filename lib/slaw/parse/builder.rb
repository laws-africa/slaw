# encoding: UTF-8

require 'uri'
require 'treetop'

module Slaw
  module Parse
    # The primary class for building Akoma Ntoso documents from plain text documents.
    #
    # The builder uses a grammar to break down a plain-text version of an act into a
    # syntax tree. This tree can then be serialized into an Akoma Ntoso compatible
    # XML document.
    #
    # @example Parse some text into a well-formed document
    #     builder = Slaw::Builder.new(parser: parser)
    #     xml = builder.parse_text(text)
    #     doc = builder.parse_xml(xml)
    #     builder.postprocess(doc)
    #
    # @example A quicker way to build a well-formed document
    #     doc = builder.parse_and_process_text(text)
    #
    class Builder
      include Slaw::Logging

      # Additional hash of options to be provided to the parser when parsing.
      attr_accessor :parse_options

      # The parser to use
      attr_accessor :parser

      # Prefix to use when generating IDs for fragments
      attr_accessor :fragment_id_prefix

      # Should the parsing re-encoding the string as ASCII?
      attr_accessor :force_ascii

      # Create a new builder.
      #
      # Specify either `:parser` or `:grammar_file` and `:grammar_class`.
      #
      # @option opts [Treetop::Runtime::CompiledParser] :parser parser to use
      # @option opts Hash :parse_options options to parse to the parser
      def initialize(opts={})
        @parser = opts[:parser]
        @parse_options = opts[:parse_optiosn] || {}
        @force_ascii = false
      end

      # Do all the work necessary to parse text into a well-formed XML document.
      #
      # @param text [String] the text to parse
      # @param parse_options [Hash] options to parse to the parser
      #
      # @return [Nokogiri::XML::Document] a well formed document
      def parse_and_process_text(text, parse_options={})
        postprocess(parse_xml(parse_text(text, parse_options)))
      end

      # Pre-process text just before parsing it using the grammar.
      #
      # @param text [String] the text to preprocess
      # @return [String] text ready to parse
      def preprocess(text)
        # our grammar doesn't handle inline table cells; instead, we break
        # inline cells into block-style cells

        # first, find all the tables
        text.gsub(/{\|(?!\|}).*?\|}/m) do |table|
          # on each table line, split inline cells into block cells
          table.split("\n").map { |line| line.gsub(/(\|\||!!)/) { |m| "\n" + m[0]} }.join("\n")
        end
      end

      # Parse text into XML. You should still run {#postprocess} on the
      # resulting XML to normalise it.
      #
      # @param text [String] the text to parse
      # @param parse_options [Hash] options to pass to the parser
      #
      # @return [String] an XML string
      def parse_text(text, parse_options={})
        text = preprocess(text)

        text = escape_utf8(text) if @force_ascii

        tree = text_to_syntax_tree(text, parse_options)
        xml = xml_from_syntax_tree(tree)

        xml = unescape_utf8(xml) if @force_ascii

        xml
      end

      # Use %-encoding to escape everything outside of the US_ASCII range,
      # including encoding % itself.
      #
      # This can have a huge performance benefit. String lookups on utf-8 strings
      # are linear in Ruby, while string lookups on US_ASCII encoded strings
      # are constant time.
      #
      # This option can only be used if the grammar doesn't include non-ascii literals.
      #
      # See https://github.com/cjheath/treetop/issues/31
      def escape_utf8(text)
        unsafe = (0..126).to_a - ['%'.ord]
        unsafe = unsafe.map { |i| '\u%04x' % i }
        unsafe = Regexp.new('[^' + unsafe.join('') + ']')

        URI::DEFAULT_PARSER.escape(text, unsafe)
      end

      def unescape_utf8(xml)
        URI.unescape(xml)
      end

      # Parse plain text into a syntax tree.
      #
      # @param text [String] the text to parse
      # @param parse_options [Hash] options to pass to the parser
      #
      # @return [Object] the root of the resulting parse tree, usually a Treetop::Runtime::SyntaxNode object
      def text_to_syntax_tree(text, parse_options={})
        logger.info("Parsing...")
        parse_options = @parse_options.dup.update(parse_options)
        tree = @parser.parse(text, parse_options)
        logger.info("Parsed!")

        if tree.nil?
          raise Slaw::Parse::ParseError.new(@parser.failure_reason || "Couldn't match to grammar",
                                            line: @parser.failure_line || 0,
                                            column: @parser.failure_column || 0)
        end

        tree
      end

      # Generate an XML document from the given syntax tree. You should still
      # run {#postprocess} on the resulting XML to normalise it.
      #
      # @param tree [Object] a Treetop::Runtime::SyntaxNode object
      #
      # @return [String] an XML string
      def xml_from_syntax_tree(tree)
        builder = ::Nokogiri::XML::Builder.new

        builder.akomaNtoso("xmlns" => Slaw.akn_namespace) do |b|
          tree.to_xml(b, fragment_id_prefix || '')
        end

        builder.to_xml(encoding: 'UTF-8')
      end

      # Parse a string into a Nokogiri::XML::Document
      #
      # @param xml [String] string to parse
      #
      # @return [Nokogiri::XML::Document]
      def parse_xml(xml)
        Nokogiri::XML(xml, &:noblanks)
      end

      # Serialise a Nokogiri::XML::Document into a string
      #
      # @param doc [Nokogiri::XML::Document] document
      #
      # @return [String] pretty printed string
      def to_xml(doc)
        doc.to_xml(indent: 2)
      end

      # Postprocess an XML document.
      #
      # @param doc [Nokogiri::XML::Document]
      #
      # @return [Nokogiri::XML::Document] the updated document
      def postprocess(doc)
        @parser.postprocess(doc)
      end

      protected

      # Look up the parent chain for an element that matches the given
      # node name
      def find_up(node, names)
        names = Array(names)

        for parent in node.ancestors
          return parent if names.include?(parent.name)
        end

        nil
      end
    end
  end
end
