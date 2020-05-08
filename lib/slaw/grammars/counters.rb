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

      # Clean a <num> value for use in an eId
      # See https://docs.oasis-open.org/legaldocml/akn-nc/v1.0/os/akn-nc-v1.0-os.html#_Toc531692306
      #
      # The number part of the identifiers of such elements corresponds to the
      # stripping of all final punctuation, meaningless separations as well as
      # redundant characters in the content of the <num> element. The
      # representation is case-sensitive
      #
      # (i) -> i
      # 1.2. -> 1-2
      # 3a bis -> 3abis
      def self.clean(num)
        num
          .gsub(/[ ()\[\]]/, '')
          .gsub(/\.+$/, '')
          .gsub(/^\.+/, '')
          .gsub(/\.+/, '-')
      end
    end
  end
end
