require 'slaw/act'

module Slaw
  # An extension of {Slaw::Act} which wraps an AkomaNtoso XML document describing an By-Law.
  #
  # There are minor differences between Acts and By-laws, the most notable being that a by-law
  # is not identified by a year and a number, and therefore has a different FRBR uri structure.
  class ByLaw < Act

    # [String] The region this by-law applies to
    attr_accessor :region
    
    # [String] A short file-like name of this by-law, unique within its year and region
    attr_accessor :name

    def _extract_id
      # /za/by-law/cape-town/2010/public-parks

      @id_uri = @meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRuri', a: NS)['value']
      empty, @country, type, @region, date, @name = @id_uri.split('/')

      # yyyy[-mm-dd]
      @year = date.split('-', 2)[0]
    end

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

    def nature
      "by-law"
    end
  end
end
