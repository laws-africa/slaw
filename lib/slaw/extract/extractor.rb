require 'mimemagic'

module Slaw
  module Extract

    # Routines for extracting and cleaning up context from other formats, such as HTML.
    class Extractor
      include Slaw::Logging

      # Extract text from a file.
      #
      # @param filename [String] filename to extract from
      #
      # @return [String] extracted text
      def extract_from_file(filename)
        mimetype = get_mimetype(filename)

        case mimetype && mimetype.type
        when 'text/html'
          extract_from_html(filename)
        when 'text/plain', nil
          extract_from_text(filename)
        else
          raise ArgumentError.new("Unsupported file type #{mimetype || 'unknown'}")
        end
      end

      def extract_from_text(filename)
        File.read(filename)
      end

      def extract_from_html(filename)
        html_to_text(File.read(filename))
      end

      def html_to_text(html)
        here = File.dirname(__FILE__)
        xslt = Nokogiri::XSLT(File.open(File.join([here, 'html_to_akn_text.xsl'])))

        text = xslt.transform(Nokogiri::HTML(html)).to_s
        # remove XML encoding at top
        text.sub(/^<\?xml [^>]*>/, '')
      end

      def get_mimetype(filename)
        File.open(filename) { |f| MimeMagic.by_magic(f) } \
          || MimeMagic.by_path(filename)
      end
    end
  end
end
