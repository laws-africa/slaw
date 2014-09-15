require 'forwardable'

module Slaw
  # A collection of Act instances.
  class DocumentCollection

    include Enumerable
    extend Forwardable

    attr_accessor :items

    def_delegators :items, :each, :<<, :length

    def initialize(items=nil)
      @items = items || []
    end

    # Find all XML files in +path+ and return
    # a list of instances of +cls+.
    def discover(path, cls=Slaw::Act)
      for fname in Dir.glob("#{path}/**/*.xml")
        @items << cls.new(fname)
      end
    end

    # Try to find an act who's FRBRuri matches this one,
    # returning nil on failure
    def for_uri(uri)
      return @items.find { |doc| doc.id_uri == uri }
    end
  end
end
