module Slaw
  # An Act wraps a single {http://www.akomantoso.org/ AkomaNtoso 2.0 XML} act document in the form of a
  # Nokogiri::XML::Document object.
  #
  # The Act object provides quick access to certain sections of the document,
  # such as the metadata and the body, as well as common operations such as
  # identifying whether it has been amended ({#amended?}), repealed
  # ({#repealed?}) or what chapters ({#chapters}), parts ({#parts}) and
  # sections ({#sections}) it contains.
  class Act
    include Slaw::Namespace

    # Allow us to jump from the XML document for an act to the
    # Act instance itself
    @@acts = {}

    # [Nokogiri::XML::Document] The underlying {Nokogiri::XML::Document} instance
    attr_accessor :doc
    
    # [Nokogiri::XML::Node] The `meta` XML node
    attr_accessor :meta

    # [Nokogiri::XML::Node] The `body` XML node
    attr_accessor :body

    # [String] The year this act was published
    attr_accessor :year 
    
    # [String] The act number in the year this act was published
    attr_accessor :num

    # [String] The FRBR URI of this act, which uniquely identifies it globally
    attr_accessor :id_uri

    # [String, nil] The source filename, or nil
    attr_accessor :filename
    
    # [Time, nil] The mtime of when the source file was last modified
    attr_accessor :mtime

    # Get the act that wraps the document that owns this XML node
    # @param node [Nokogiri::XML::Node]
    # @return [Act] owning act
    def self.for_node(node)
      @@acts[node.document]
    end

    # Create a new instance, loading from `filename` if given.
    # @param filename [String] filename to load XML from
    def initialize(filename=nil)
      self.load(filename) if filename
    end

    # Load the XML in `filename` into this instance
    # @param filename [String] filename
    def load(filename)
      @filename = filename
      @mtime = File::mtime(@filename)

      File.open(filename) { |f| parse(f) }
    end
    
    # Parse the XML contained in the file-like object `io`
    # @param io [file-like] io object with XML
    def parse(io)
      @doc = Nokogiri::XML(io)
      @meta = @doc.at_xpath('/a:akomaNtoso/a:act/a:meta', a: NS)
      @body = @doc.at_xpath('/a:akomaNtoso/a:act/a:body', a: NS)

      @@acts[@doc] = self

      _extract_id
    end

    # Parse the FRBR Uri into its constituent parts
    def _extract_id
      @id_uri = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS)['value']
      empty, @country, type, date, @num = @id_uri.split('/')

      # yyyy-mm-dd
      @year = date.split('-', 2)[0]
    end

    # An applicable short title for this act, either from the `FRBRalias` element
    # or based on the act number and year.
    # @return [String]
    def short_title
      node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: NS)
      node ? node['value'] : "Act #{num} of #{year}"
    end

    # Has this act been amended? This is determined by testing the `contains`
    # attribute of the `act` root element.
    #
    # @return [Boolean]
    def amended?
      @doc.at_xpath('/a:akomaNtoso/a:act', a: NS)['contains'] != 'originalVersion'
    end

    # Get a list of {Slaw::LifecycleEvent} objects for amendment events, in date order.
    # @return [Array<Slaw::LifecycleEvent>] possibly empty list of lifecycle events
    def amendment_events
      @meta.xpath('./a:lifecycle/a:eventRef[@type="amendment"]', a: NS).map do |event|
        LifecycleEvent.new(event)
      end.sort_by { |e| e.date }
    end

    # Mark this act as being amended by another act, either `act`
    # or the details in `opts`.
    #
    # It is assumed that there can be only one amendment event on a particular
    # date. An existing amendment on this date is overwritten.
    #
    # @option opts [String] :uri uri of the amending act
    # @option opts [String] :title title of the amending act
    # @option opts [String] :date date of the amendment (YYYY-MM-DD)
    def amended_by!(act, opts={})
      if act
        opts[:uri] ||= act.id_uri
        opts[:title] ||= act.short_title
        opts[:date] ||= act.publication['date']
      end

      date = opts[:date]
      source_id = "amendment-#{date}"

      # assume we now hold a single version and not the original version
      @doc.at_xpath('/a:akomaNtoso/a:act', a: NS)['contains'] = 'singleVersion'

      # add the lifecycle event
      lifecycle = @meta.at_xpath('./a:lifecycle', a: NS)
      if not lifecycle
        lifecycle = @doc.create_element('lifecycle', source: "#this")
        @meta.at_xpath('./a:publication', a: NS).after(lifecycle)
      end

      event = lifecycle.at_xpath('./a:eventRef[@date="' + date + '"][@type="amendment"]', a: NS)
      if event
        # clear up old event
        src = @doc.at_css(event['source'])
        src.remove if src
      else
        # new event
        event = @doc.create_element('eventRef', type: 'amendment')
        lifecycle << event
      end

      event['date'] = date
      event['id'] = "amendment-event-#{date}"
      event['source'] = '#' + source_id

      # add reference
      ref = @doc.create_element('passiveRef',
                                id: source_id,
                                href: opts[:uri],
                                showAs: opts[:title])

      @meta.at_xpath('./a:references/a:TLCTerm', a: NS).before(ref)
    end

    # Does this Act have parts?
    # @return [Boolean]
    def parts?
      !parts.empty?
    end

    # Top-level parts of this act. Parts inside chapters are ignored.
    # @return [Array<Nokogiri::XML::Node>] part nodes
    def parts
      @body.xpath('./a:part', a: NS)
    end

    # Does this Act have chapters?
    # @return [Boolean]
    def chapters?
      !chapters.empty?
    end

    # Top-level chapters of this act. Chapters inside parts are ignored.
    # @return [Array<Nokogiri::XML::Node>] chapter nodes
    def chapters
      @body.xpath('./a:chapter', a: NS)
    end
    
    # Sections of this act
    # @return [Array<Nokogiri::XML::Node>] section nodes
    def sections
      @body.xpath('.//a:section', a: NS)
    end

    # The primary definitions section of this act, identified by
    # either an `id` of `definitions` or the first section with a heading
    # of `Definitions`.
    #
    # @return [Nokogiri::XML::Node, nil] definitions node or nil
    def definitions
      # try looking for the definition list
      defn = @body.at_css('#definitions')
      return defn.parent if defn

      # try looking for the heading
      defn = @body.at_xpath('.//a:section/a:heading[text() = "Definitions"]', a: NS)
      return defn.parent if defn

      nil
    end

    # An act can contain schedules, additional (generally free-form) documents
    # that are addendums to the the main body. A definition element must be
    # part of a separate `component` and have a `doc` element with a name attribute
    # of `schedules`.
    #
    # @return [Nokogiri::XML::Node, nil] schedules document node
    def schedules
      @doc.at_xpath('/a:akomaNtoso/a:components/a:component/a:doc[@name="schedules"]/a:mainBody', a: NS)
    end

    # Get a map from term ids to `[term, defn]` pairs,
    # where `term+ is the plain text term and `defn` is
    # the {Nokogiri::XML::Node} containing the definition.
    #
    # @return Hash{String => [String, Nokogiri::XML::Node]} map from strings to `[term, definition]` pairs
    def term_definitions
      terms = {}

      @meta.xpath('a:references/a:TLCTerm', a: NS).each do |node|
        # <TLCTerm id="term-affected_land" href="/ontology/term/this.eng.affected_land" showAs="affected land"/>

        # find the point with id 'def-term-foo'
        defn = @body.at_xpath(".//*[@id='def-#{node['id']}']", a: NS)
        next unless defn

        terms[node['id']] = [node['showAs'], defn]
      end

      terms
    end

    # Returns the publication element, if any.
    #
    # @return [Nokogiri::XML::Node, nil]
    def publication
      @meta.at_xpath('./a:publication', a: NS)
    end

    # Has this by-law been repealed?
    #
    # @return [Boolean]
    def repealed?
      !!repealed_on
    end

    # The date on which this act was repealed, or nil if never repealed
    #
    # @return [String] date of repeal or nil
    def repealed_on
      repeal_el = repeal
      repeal_el ? Time.parse(repeal_el['date']) : nil
    end

    # The element representing the reference that caused the repeal of this
    # act, or nil.
    #
    # @return [Nokogiri::XML::Node] element of reference to repealing act, or nil
    def repealed_by
      repeal_el = repeal
      return nil unless repeal_el

      source_id = repeal_el['source'].sub(/^#/, '')
      @meta.at_xpath("./a:references/a:passiveRef[@id='#{source_id}']", a: NS)
    end

    # The XML element representing the event of repeal of this act, or nil
    #
    # @return [Nokogiri::XML::Node]
    def repeal
      # <lifecycle source="#this">
      #   <eventRef id="e1" date="2010-07-28" source="#original" type="generation"/>
      #   <eventRef id="e2" date="2012-04-26" source="#amendment-1" type="amendment"/>
      #   <eventRef id="e3" date="2014-01-17" source="#repeal" type="repeal"/>
      # </lifecycle>
      @meta.at_xpath('./a:lifecycle/a:eventRef[@type="repeal"]', a: NS)
    end

    # The date at which this particular XML manifestation of this document was generated.
    #
    # @return [String] date, YYYY-MM-DD
    def manifestation_date
      node = @meta.at_xpath('./a:identification/a:FRBRManifestation/a:FRBRdate[@name="Generation"]', a: NS)
      node && node['date']
    end

    # The underlying nature of this act, usually `act` although subclasses my override this.
    def nature
      "act"
    end

    def inspect
      "<#{self.class.name} @id_uri=\"#{@id_uri}\">"
    end
  end

end
