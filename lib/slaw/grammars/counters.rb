module Slaw
  module Grammars
    class Counters
      # Counters for generating element IDs. This is a hash from the element ID
      # prefix, to another hash that maps the element type name to a count.
      #
      # For backwards compatibility, counters always start at -1, and must be
      # incremented before being used. This ensures that element ids start at 0.
      # This is NOT compatible with AKN 3.0 which requires that element numbers
      # start at 1.
      #
      # eg.
      #
      #   section-1 => paragraph => 2
      #
      @@counters = Hash.new{ |h, k| h[k] = Hash.new(-1) }

      def self.counters
        @@counters
      end

      def self.reset!
        @@counters.clear
      end
    end
  end
end
