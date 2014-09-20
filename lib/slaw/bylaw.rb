require 'slaw/act'

module Slaw
  # An extension of {Slaw::Act} which wraps an AkomaNtoso XML document describing an By-Law.
  #
  # There are minor differences between Acts and By-laws, the most notable being that a by-law
  # is not identified by a year and a number, and therefore has a different FRBR uri structure.
  class ByLaw < Act

    # [String] The code of the region this by-law applies to
    attr_reader :region
    
    # [String] A short file-like name of this by-law, unique within its year and region
    attr_reader :name

    # ByLaws don't have numbers, use their short-name instead
    def num
      name
    end

    def title
      node = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: NS)
      title = node ? node['value'] : "(Unknown)"

      if amended? and not title.end_with?("as amended")
        title = title + " as amended"
      end

      title
    end

    # Set the short (file-like) name for this bylaw. This changes the {#id_uri}.
    def name=(value)
      @name = value
      rebuild_id_uri
    end

    # Set the region code for this bylaw. This changes the {#id_uri}.
    def region=(value)
      @region = value
      rebuild_id_uri
    end

    protected

    def extract_id_uri
      # /za/by-law/cape-town/2010/public-parks

      @id_uri = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS)['value']
      empty, @country, @nature, @region, date, @name = @id_uri.split('/')

      # yyyy[-mm-dd]
      @year = date.split('-', 2)[0]
    end

    def build_id_uri
      # /za/by-law/cape-town/2010/public-parks
      "/#{@country}/#{@nature}/#{@region}/#{@year}/#{@name}"
    end

  end
end
