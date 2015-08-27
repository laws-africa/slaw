# encoding: UTF-8

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
      include Slaw::Namespace
      include Slaw::Logging

      @@parsers = {}

      # Additional hash of options to be provided to the parser when parsing.
      attr_accessor :parse_options

      # Prefix to use when generating IDs for fragments
      attr_accessor :fragment_id_prefix

      # Create a new builder.
      #
      # Specify either `:parser` or `:grammar_file` and `:grammar_class`.
      #
      # @option opts [Treetop::Runtime::CompiledParser] :parser parser to use
      # @option opts [String] :grammar_file grammar filename to load a parser from
      # @option opts [String] :grammar_class name of the class that the grammar will generate
      def initialize(opts={})
        if opts[:parser]
          @parser = opts[:parser]
        elsif opts[:grammar_file] and opts[:grammar_class]
          if @@parsers[opts[:grammar_class]]
            # already compiled the grammar, just use it
            @parser = @@parsers[opts[:grammar_class]]
          else
            # load the grammar
            Treetop.load(opts[:grammar_file])
            cls = eval(opts[:grammar_class])
            @parser = cls.new
          end
        else
          raise ArgumentError.new("Specify either :parser or :grammar_file and :grammar_class")
        end

        @parse_options = {}
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

      # Parse text into XML. You should still run {#postprocess} on the
      # resulting XML to normalise it.
      #
      # @param text [String] the text to parse
      # @param parse_options [Hash] options to pass to the parser
      #
      # @return [String] an XML string
      def parse_text(text, parse_options={})
        tree = text_to_syntax_tree(text, parse_options)
        xml_from_syntax_tree(tree)
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

        builder.akomaNtoso("xmlns:xsi"=> "http://www.w3.org/2001/XMLSchema-instance", 
                           "xsi:schemaLocation" => "http://www.akomantoso.org/2.0 akomantoso20.xsd",
                           "xmlns" => NS) do |b|
          args = [b]

          # should we provide an id prefix?
          arity = tree.method('to_xml').arity 
          arity = arity.abs-1 if arity < 0
          args << (fragment_id_prefix || "") if arity > 1

          tree.to_xml(*args)
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
        normalise_headings(doc)
        find_short_title(doc)
        nest_blocklists(doc)

        doc
      end

      # Change CAPCASE headings into Sentence case.
      #
      # @param doc [Nokogiri::XML::Document]
      def normalise_headings(doc)
        logger.info("Normalising headings")

        nodes = doc.xpath('//a:body//a:heading/text()', a: NS) +
                doc.xpath('//a:component/a:doc[@name="schedules"]//a:heading/text()', a: NS)

        nodes.each do |heading|
          if !(heading.content =~ /[a-z]/)
            heading.content = heading.content.downcase.gsub(/^\w/) { $&.upcase }
          end
        end
      end

      # Find the short title and add it as an FRBRalias element in the meta section
      #
      # @param doc [Nokogiri::XML::Document]
      def find_short_title(doc)
        logger.info("Finding short title")

        # Short title and commencement 
        # 8. This Act shall be called the Legal Aid Amendment Act, 1996, and shall come 
        # into operation on a date fixed by the President by proclamation in the Gazette. 

        doc.xpath('//a:body//a:heading[contains(text(), "hort title")]', a: NS).each do |heading|
          section = heading.parent.at_xpath('a:subsection', a: NS)
          if section and section.text =~ /this act (is|shall be called) the (([a-zA-Z\(\)]\s*)+, \d\d\d\d)/i
            short_title = $2

            logger.info("+ Found title: #{short_title}")

            node = doc.at_xpath('//a:meta//a:FRBRalias', a: NS)
            node['value'] = short_title
            break
          end
        end
      end

      # Find definitions of terms and introduce them into the
      # meta section of the document.
      #
      # @param doc [Nokogiri::XML::Document]
      def link_definitions(doc)
        logger.info("Finding and linking definitions")

        terms = find_definitions(doc)
        add_terms_to_references(doc, terms)
        find_term_references(doc, terms)
        renumber_terms(doc)
      end

      # Find `def` elements in the document and return a Hash from
      # term ids to the text of each term
      #
      # @param doc [Nokogiri::XML::Document]
      #
      # @return [Hash{String, String}]
      def find_definitions(doc)
        guess_at_definitions(doc)

        terms = {}
        doc.xpath('//a:def', a: NS).each do |defn|
          # <p>"<def refersTo="#term-affected_land">affected land</def>" means land in respect of which an application has been lodged in terms of section 17(1);</p>
          id = defn['refersTo'].sub(/^#/, '')
          term = defn.content
          terms[id] = term

          logger.info("+ Found definition for: #{term}")
        end

        terms
      end

      # Find defined terms in the document.
      #
      # This looks for heading elements with the words 'definitions' or 'interpretation',
      # and then looks for phrases like
      #
      #   "this word" means something...
      #
      # It identifies "this word" as a defined term and wraps it in a def tag with a refersTo
      # attribute referencing the term being defined. The surrounding block
      # structure is also has its refersTo attribute set to the term. This way, the term
      # is both marked as defined, and the container element with the full
      # definition of the term is identified.
      def guess_at_definitions(doc)
        doc.xpath('//a:section', a: NS).select do |section|
          # sections with headings like Definitions
          heading = section.at_xpath('a:heading', a: NS)
          heading && heading.content =~ /definitions|interpretation/i
        end.each do |section|
          # find items like "foo" means blah...
          
          section.xpath('.//a:p|.//a:listIntroduction', a: NS).each do |container|
            # only if we don't already have a definition here
            next if container.at_xpath('a:def', a: NS)

            # get first text node
            text = container.children.first
            next if (not text or not text.text?)

            match = /^\s*["“”](.+?)["“”]/.match(text.text)
            if match
              term = match.captures[0]
              term_id = 'term-' + term.gsub(/[^a-zA-Z0-9_-]/, '_')

              # <p>"<def refersTo="#term-affected_land">affected land</def>" means land in respect of which an application has been lodged in terms of section 17(1);</p>
              refersTo = "##{term_id}"
              defn = doc.create_element('def', term, refersTo: refersTo)
              rest = match.post_match

              text.before(defn)
              defn.before(doc.create_text_node('"'))
              text.content = '"' + rest

              # adjust the container's refersTo attribute
              parent = find_up(container, ['item', 'point', 'blockList', 'list', 'paragraph', 'subsection', 'section', 'chapter', 'part'])
              parent['refersTo'] = refersTo
            end
          end
        end
      end
      
      def add_terms_to_references(doc, terms)
        refs = doc.at_xpath('//a:meta/a:references', a: NS)
        unless refs
          refs = doc.create_element('references', source: "#this")
          doc.at_xpath('//a:meta/a:identification', a: NS).after(refs)
        end

        # nuke all existing term reference elements
        refs.xpath('a:TLCTerm', a: NS).each { |el| el.remove }

        for id, term in terms
          # <TLCTerm id="term-applicant" href="/ontology/term/this.eng.applicant" showAs="Applicant"/>
          refs << doc.create_element('TLCTerm',
                                     id: id,
                                     href: "/ontology/term/this.eng.#{id.gsub(/^term-/, '')}",
                                     showAs: term)
        end
      end

      # Find and decorate references to terms in the document.
      # The +terms+ param is a hash from term_id to actual term.
      def find_term_references(doc, terms)
        logger.info("+ Finding references to terms")

        i = 0

        # sort terms by the length of the defined term, desc,
        # so that we don't find short terms inside longer
        # terms
        terms = terms.to_a.sort_by { |pair| -pair[1].size }

        # look for each term
        for term_id, term in terms
          doc.xpath('//a:body//text()', a: NS).each do |text|
            # replace all occurrences in this text node

            # unless we're already inside a def or term element
            next if (["def", "term"].include?(text.parent.name))

            # don't link to a term inside its own definition
            owner = find_up(text, 'subsection')
            next if owner and owner.at_xpath(".//a:def[@refersTo='##{term_id}']", a: NS)

            while posn = (text.content =~ /\b#{Regexp::escape(term)}\b/)
              # <p>A delegation under subsection (1) shall not prevent the <term refersTo="#term-Minister" id="trm357">Minister</term> from exercising the power himself or herself.</p>
              node = doc.create_element('term', term, refersTo: "##{term_id}", id: "trm#{i}")

              pre = (posn > 0) ? text.content[0..posn-1] : nil
              post = text.content[posn+term.length..-1]

              text.before(node)
              node.before(doc.create_text_node(pre)) if pre
              text.content = post

              i += 1
            end
          end
        end
      end

      # recalculate ids for <term> elements
      def renumber_terms(doc)
        logger.info("Renumbering terms")

        doc.xpath('//a:term', a: NS).each_with_index do |term, i|
          term['id'] = "trm#{i}"
        end
      end

      # Correctly nest blocklists.
      #
      # The grammar gives us flat blocklists, we need to introspect the
      # numbering of the lists to correctly nest them.
      #
      # @param doc [Nokogiri::XML::Document]
      def nest_blocklists(doc)
        logger.info("Nesting blocklists")

        Slaw::Parse::Blocklists.nest_blocklists(doc)
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
