module Slaw
  # Wraps an AkomaNtoso 2.0 XML document describing an Act.
  class Act
    include Slaw::Namespace

    # Allow us to jump from the XML document for an act to the
    # Act instance itself
    @@acts = {}

    attr_accessor :doc, :meta, :body, :num, :year, :id_uri
    attr_accessor :filename, :mtime

    def self.for_node(node)
      @@acts[node.document]
    end

    # Create a new instance
    def initialize(filename=nil)
      self.load(filename) if filename
    end

    # Load the XML from +filename+
    def load(filename)
      @filename = filename
      @mtime = File::mtime(@filename)

      File.open(filename) { |f| parse(f) }
    end
    
    # Parse the XML contained in the file-like object +io+
    def parse(io)
      @doc = Nokogiri::XML(io)
      @meta = @doc.at_xpath('/a:akomaNtoso/a:act/a:meta', a: NS)
      @body = @doc.at_xpath('/a:akomaNtoso/a:act/a:body', a: NS)

      @@acts[@doc] = self

      extract_id
    end

    def extract_id
      @id_uri = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS)['value']
      empty, @country, type, date, @num = @id_uri.split('/')

      # yyyy-mm-dd
      @year = date.split('-', 2)[0]
    end

    def short_title
      unless @short_title
        node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: NS)
        if node
          @short_title = node['value']
        else
          @short_title = "Act #{num} of #{year}"
        end
      end

      @short_title
    end

    # Has this act been amended?
    def amended?
      @doc.at_xpath('/a:akomaNtoso/a:act', a: NS)['contains'] != 'originalVersion'
    end

    # a list of LifecycleEvent objects for amendment events, in date order
    def amendment_events
      @meta.xpath('./a:lifecycle/a:eventRef[@type="amendment"]', a: NS).map do |event|
        LifecycleEvent.new(event)
      end.sort_by { |e| e.date }
    end

    # Mark this act as being amended by another act, either +act+
    # or the details in +opts+:
    #
    #   :uri: uri of the amending act
    #   :title: title of the amending act
    #   :date: date of the amendment
    #
    # It is assumed that there can be only one amendment event on a particular
    # date. An existing amendment on this date is overwritten.
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
    def parts?
      !parts.empty?
    end

    def parts
      @body.xpath('./a:part', a: NS)
    end

    def chapters?
      !chapters.empty?
    end

    def chapters
      @body.xpath('./a:chapter', a: NS)
    end
    
    def sections
      @body.xpath('.//a:section', a: NS)
    end

    # The XML node representing the definitions section
    def definitions
      # try looking for the definition list
      defn = @body.at_css('#definitions')
      return defn.parent if defn

      # try looking for the heading
      defn = @body.at_xpath('.//a:section/a:heading[text() = "Definitions"]', a: NS)
      return defn.parent if defn

      nil
    end

    # The XML node representing the schedules document
    def schedules
      @doc.at_xpath('/a:akomaNtoso/a:components/a:component/a:doc[@name="schedules"]/a:mainBody', a: NS)
    end

    # Get a map from term ids to +[term, defn]+ pairs,
    # where +term+ is the text term NS+defn+ is
    # the XML node with the definition in it.
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
    def publication
      @meta.at_xpath('./a:publication', a: NS)
    end

    # Has this by-law been repealed?
    def repealed?
      !!repealed_on
    end

    # The date on which this act was repealed, or nil if never repealed
    def repealed_on
      repeal_el = repeal
      repeal_el ? Time.parse(repeal_el['date']) : nil
    end

    # The element representing the reference that caused the repeal of this
    # act, or nil
    def repealed_by
      repeal_el = repeal
      return nil unless repeal_el

      source_id = repeal_el['source'].sub(/^#/, '')
      @meta.at_xpath("./a:references/a:passiveRef[@id='#{source_id}']", a: NS)
    end

    # The XML element representing the repeal of this act, or nil
    def repeal
      # <lifecycle source="#this">
      #   <eventRef id="e1" date="2010-07-28" source="#original" type="generation"/>
      #   <eventRef id="e2" date="2012-04-26" source="#amendment-1" type="amendment"/>
      #   <eventRef id="e3" date="2014-01-17" source="#repeal" type="repeal"/>
      # </lifecycle>
      @meta.at_xpath('./a:lifecycle/a:eventRef[@type="repeal"]', a: NS)
    end

    def manifestation_date
      node = @meta.at_xpath('./a:identification/a:FRBRManifestation/a:FRBRdate[@name="Generation"]', a: NS)
      node && node['date']
    end

    def nature
      "act"
    end

    def inspect
      "<#{self.class.name} @id_uri=\"#{@id_uri}\">"
    end
  end

end
