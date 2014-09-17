require 'forwardable'

module Slaw
  # A collection of Act instances.
  #
  # This is useful for looking up acts by their FRBR uri and for
  # loading a collection of XML act documents.
  #
  # This collection is enumerable and can be iterated over. Use {#items} to
  # access the underlying array of objects.
  #
  # @example Load a collection of acts and then iterate over them.
  #
  #     acts = Slaw::DocumentCollection.new
  #     acts.discover('/path/to/acts/')
  #
  #     for act in acts
  #       puts act.short_name
  #     end
  #
  class DocumentCollection

    include Enumerable
    extend Forwardable

    # [Array<Act>] The underlying array of acts
    attr_accessor :items

    def_delegators :items, :each, :<<, :length

    def initialize(items=nil)
      @items = items || []
    end

    # Find all XML files in `path` and add them into this
    # collection.
    #
    # @param path [String] the path to glob for xml files
    # @param cls [Class] the class to instantiate for each file
    #
    # @return [DocumentCollection] this collection
    def discover(path, cls=Slaw::Act)
      for fname in Dir.glob("#{path}/**/*.xml")
        @items << cls.new(fname)
      end

      self
    end

    # Try to find an act who's FRBRuri matches this one,
    # returning nil on failure
    #
    # @param [String] the uri to look for
    #
    # @return [Act, nil] the act, or nil
    def for_uri(uri)
      return @items.find { |doc| doc.id_uri == uri }
    end
  end
end
