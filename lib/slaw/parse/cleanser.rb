# encoding: utf-8

module Slaw
  module Parse
    # Helper class to run various cleanup routines on plain text.
    #
    # Some of these routines can safely be run multiple times,
    # others are meant to be run only once.
    class Cleanser

      # Run general cleanup, such as stripping bad chars and
      # removing unnecessary whitespace. This is idempotent
      # and safe to run multiple times.
      def cleanup(s)
        s = scrub(s)
        s = correct_newlines(s)
        s = expand_tabs(s)
        s = chomp(s)
        s = enforce_newline(s)
      end

      # ------------------------------------------------------------------------

      def remove_empty_lines(s)
        s.gsub(/\n\s*$/, '')
      end

      # line endings
      def correct_newlines(s)
        s.gsub(/\r\n/, "\n")\
         .gsub(/\r/, "\n")
      end

      # strip invalid bytes and ones we don't like
      def scrub(s)
        # we often get this unicode codepoint in the string, nuke it
        s.gsub([65532].pack('U*'), '')\
         .gsub(/\n*/, '')\
         .gsub(/–/, '-')
      end

      # tabs to spaces
      def expand_tabs(s)
        s.gsub(/\t/, ' ')\
         .gsub("\u00A0", ' ') # non-breaking space
      end

      # Get rid of whitespace at the end of lines and at the start and end of the 
      # entire string.
      def chomp(s)
        # trailing whitespace at end of lines
        s = s.gsub(/ +$/, '')

        # whitespace on either side
        s.strip
      end

      def enforce_newline(s)
        # ensure string ends with a newline
        s.end_with?("\n") ? s : (s + "\n")
      end
    end
  end
end
