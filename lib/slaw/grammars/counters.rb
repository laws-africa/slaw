module Slaw
  module Grammars
    class Counters
      # Counters for generating element IDs. This is a hash from the element ID
      # prefix, to another hash that maps the element type name to a count.
      #
      # Counters always start at 0, and must be incremented before being used.
      # This ensures that element ids start at 1, as per AKN 3.0 spec.
      #
      # eg.
      #
      #   section-1 => paragraph => 2
      #
      @@counters = Hash.new{ |h, k| h[k] = Hash.new(0) }

      def self.counters
        @@counters
      end

      def self.reset!
        @@counters.clear
      end

      # Clean a <num> value for use in an eId
      # See https://docs.oasis-open.org/legaldocml/akn-nc/v1.0/os/akn-nc-v1.0-os.html#_Toc531692306
      #
      # "The number part of the identifiers of such elements corresponds to the
      # stripping of all final punctuation, meaningless separations as well as
      # redundant characters in the content of the <num> element. The
      # representation is case-sensitive."
      #
      # Our algorithm is:
      # 1. strip all leading and trailing whitespace and punctuation (using the unicode punctuation blocks)
      # 2. strip all whitespace
      # 3. replace all remaining punctuation with a hyphen.
      #
      # The General Punctuation block is \u2000-\u206F, and the Supplemental Punctuation block is \u2E00-\u2E7F.
      #
      # (i) -> i
      # 1.2. -> 1-2
      # “2.3“ -> 2-3
      # 3a bis -> 3abis
      def self.clean(num)
        # leading whitespace and punctuation
        num.gsub!(/^[\s\u{2000}-\u{206f}\u{2e00}-\u{2e7f}!"#$%&'()*+,\-.\/:;<=>?@\[\]^_`{|}~]+/, '')
        # trailing whitespace and punctuation
        num.gsub!(/[\s\u{2000}-\u{206f}\u{2e00}-\u{2e7f}!"#$%&'()*+,\-.\/:;<=>?@\[\]^_`{|}~]+$/, '')
        # whitespace
        num.gsub!(/\s/, '')
        # remaining punctuation to a hyphen
        num.gsub!(/[\u{2000}-\u{206f}\u{2e00}-\u{2e7f}!"#$%&'()*+,\-.\/:;<=>?@\[\]^_`{|}~]+/, '-')
        num
      end
    end
  end
end
