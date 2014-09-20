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
    attr_reader :meta

    # [Nokogiri::XML::Node] The `body` XML node
    attr_reader :body

    # [String] The year this act was published
    attr_reader :year
    
    # [String] The act number in the year this act was published
    attr_reader :num

    # [String] The FRBR URI of this act, which uniquely identifies it globally
    attr_reader :id_uri

    # [String, nil] The source filename, or nil
    attr_reader :filename
    
    # [Time, nil] The mtime of when the source file was last modified
    attr_reader :mtime

    # [String] The underlying nature of this act, usually `act` although subclasses my override this.
    attr_reader :nature

    # [Nokogiri::XML::Schema] schema to validate against
    attr_accessor :schema

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
      @schema = nil
    end

    # Load the XML in `filename` into this instance
    # @param filename [String] filename
    def load(filename)
      @filename = filename
      @mtime = File::mtime(@filename)

      File.open(filename) { |f| parse(f) }
    end
    
    # Parse the XML contained in the file-like or String object `io`
    #
    # @param io [String, file-like] io object or String with XML
    def parse(io)
      self.doc = Nokogiri::XML(io)
    end

    # Set the XML document backing this bylaw.
    #
    # @param doc [Nokogiri::XML::Document] document
    def doc=(doc)
      @doc = doc
      @meta = @doc.at_xpath('/a:akomaNtoso/a:act/a:meta', a: NS)
      @body = @doc.at_xpath('/a:akomaNtoso/a:act/a:body', a: NS)

      @@acts[@doc] = self

      extract_id_uri
    end

    # Directly set the FRBR URI of this act. This must be a well-formed URI,
    # such as `/za/act/2002/2`. This will, in turn, update the {#year}, {#nature},
    # {#country} and {#num} attributes.
    #
    # You probably don't want to use this method. Instead, set each component
    # (such as {#date}) manually.
    #
    # @param uri [String] new URI
    def id_uri=(uri)
      for component, xpath in [['main',      '//a:act/a:meta/a:identification'],
                               ['schedules', '//a:component/a:doc/a:meta/a:identification']] do
        ident = @doc.at_xpath(xpath, a: NS)
        next if not ident

        # work
        ident.at_xpath('a:FRBRWork/a:FRBRthis', a: NS)['value'] = "#{uri}/#{component}"
        ident.at_xpath('a:FRBRWork/a:FRBRuri', a: NS)['value'] = uri

        # expression
        ident.at_xpath('a:FRBRExpression/a:FRBRthis', a: NS)['value'] = "#{uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRExpression/a:FRBRuri', a: NS)['value'] = "#{uri}/eng@"

        # manifestation
        ident.at_xpath('a:FRBRManifestation/a:FRBRthis', a: NS)['value'] = "#{uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRManifestation/a:FRBRuri', a: NS)['value'] = "#{uri}/eng@"
      end

      extract_id_uri
    end

    # The date at which this act was first created/promulgated.
    #
    # @return [String] date, YYYY-MM-DD
    def date
      node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRdate[@name="Generation"]', a: NS)
      node && node['date']
    end

    # Set the date at which this act was first created/promulgated. This is usually the same
    # as the publication date but this is not enforced.
    #
    # This also updates the {#year} of this act, which in turn updates the {#id_uri}.
    #
    # @param date [String] date, YYYY-MM-DD
    def date=(value)
      for frbr in ['FRBRWork', 'FRBRExpression'] do
        @meta.at_xpath("./a:identification/a:#{frbr}/a:FRBRdate[@name=\"Generation\"]", a: NS)['date'] = value
      end

      self.year = value.split('-')[0]
    end

    # Set the year for this act. You probably want to call {#date=} instead.
    #
    # This will also update the {#id_uri} but will not change {#date} at all.
    #
    # @param year [String, Number] year
    def year=(year)
      @year = year.to_s
      rebuild_id_uri
    end

    # An applicable short title for this act, either from the `FRBRalias` element
    # or based on the act number and year.
    # @return [String]
    def title
      node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: NS)
      node ? node['value'] : "Act #{num} of #{year}"
    end

    # Change the title of this act.
    def title=(value)
      node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: NS)
      unless node
        node = @doc.create_element('FRBRalias')
        @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS).after(node)
      end

      node['value'] = value
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
    # @return {String => List(String, Nokogiri::XML::Node)} map from strings to `[term, definition]` pairs
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

    # Update the publication details of the act. All elements are optional.
    #
    # @option details [String] :name name of the publication
    # @option details [String] :number publication number
    # @option details [String] :date date of publication (YYYY-MM-DD)
    def published!(details)
      node = @meta.at_xpath('./a:publication', a: NS)
      unless node
        node = @doc.create_element('publication')
        @meta.at_xpath('./a:identification', a: NS).after(node)
      end

      node['showAs'] = details[:name] if details.has_key? :name
      node['name'] = details[:name] if details.has_key? :name
      node['date'] = details[:date] if details.has_key? :date
      node['number'] = details[:number] if details.has_key? :number
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

    # Validate the XML behind this document against the Akoma Ntoso schema and return
    # any errors.
    #
    # @return [Object] array of errors, possibly empty
    def validate
      @schema ||= Dir.chdir(File.dirname(__FILE__) + "/schemas") { Nokogiri::XML::Schema(File.read('akomantoso20.xsd')) }
      @schema.validate(@doc)
    end

    # Does this document validate against the schema?
    #
    # @see {#validate}
    def validates?
      validate.empty?
    end

    # Serialise the XML for this act, passing `args` to the Nokogiri serialiser.
    # The most useful argument is usually `indent: 2` if you like your XML perdy.
    #
    # @return [String] serialized XML
    def to_xml(*args)
      @doc.to_xml(*args)
    end

    def inspect
      "<#{self.class.name} @id_uri=\"#{@id_uri}\">"
    end

    protected

    # Parse the FRBR Uri into its constituent parts
    def extract_id_uri
      @id_uri = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS)['value']
      empty, @country, @nature, date, @num = @id_uri.split('/')

      # yyyy-mm-dd
      @year = date.split('-', 2)[0]
    end

    def build_id_uri
      # /za/act/2002/3
      "/#{@country}/#{@nature}/#{@year}/#{@num}"
    end

    # This rebuild's the FRBR uri for this document using its constituent components. It will
    # update the XML then re-split the URI and grab its components.
    def rebuild_id_uri
      self.id_uri = build_id_uri
    end
  end

end
