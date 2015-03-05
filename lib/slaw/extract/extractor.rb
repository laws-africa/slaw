require 'open3'
require 'tempfile'
require 'mimemagic'

module Slaw
  module Extract

    # Routines for extracting and cleaning up context from other formats, such as PDF.
    #
    # You may need to set the location of the `pdftotext` binary. 
    #
    # On Mac OS X, use `brew install xpdf` or download from http://www.foolabs.com/xpdf/download.html
    #
    # On Heroku, you'll need to do some hoop jumping, see http://theprogrammingbutler.com/blog/archives/2011/07/28/running-pdftotext-on-heroku/
    class Extractor
      include Slaw::Logging

      @@pdftotext_path = "pdftotext"

      # Object with text cleaning helpers
      attr_accessor :cleanser

      def initialize
        @cleanser = Slaw::Parse::Cleanser.new
      end

      # Extract text from a file and run cleanup on it.
      #
      # @param filename [String] filename to extract from
      #
      # @return [String] extracted text
      def extract_from_file(filename)
        ext = filename[-4..-1].downcase

        mimetype = get_mimetype(filename)

        case mimetype && mimetype.type
        when 'application/pdf'
          extract_from_pdf(filename)
        when 'text/plain', nil
          extract_from_text(filename)
        else
          if mimetype.text?
            extract_from_text(filename)
          else
            raise ArgumentError.new("Unsupported file type #{ext} (#{mimetype || unknown})")
          end
        end
      end

      # Extract text from a PDF
      #
      # @param filename [String] filename to extract from
      #
      # @return [String] extracted text
      def extract_from_pdf(filename)
        retried = false

        while true
          cmd = pdf_to_text_cmd(filename)
          logger.info("Executing: #{cmd}")
          stdout, status = Open3.capture2(*cmd)

          case status.exitstatus
          when 0
            return cleanup(stdout)
          when 3
            return nil if retried
            retried = true
            self.remove_pdf_password(filename)
          else
            return nil
          end
        end
      end

      # Build a command for the external PDF-to-text utility.
      #
      # @param filename [String] the pdf file
      #
      # @return [Array<String>] command and params to execute
      def pdf_to_text_cmd(filename)
        [Extractor.pdftotext_path, "-enc", "UTF-8", filename, "-"]
      end

      def extract_from_text(filename)
        cleanup(File.read(filename))
      end

      # Run general once-off cleanup of extracted text.
      def cleanup(text)
        text = @cleanser.cleanup(text)
        text = @cleanser.remove_empty_lines(text)
        text = @cleanser.reformat(text)

        text
      end

      def remove_pdf_password(filename)
        file = Tempfile.new('steno')
        begin
          logger.info("Trying to remove password from #{filename}")
          cmd = "gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=#{file.path} -c .setpdfwrite -f #{filename}".split(" ")
          logger.info("Executing: #{cmd}")
          Open3.capture2(*cmd)
          FileUtils.move(file.path, filename)
        ensure
          file.close
          file.unlink
        end
      end

      def get_mimetype(filename)
        File.open(filename) { |f| MimeMagic.by_magic(f) } \
          || MimeMagic.by_path(filename)
      end

      # Get location of the pdftotext executable for all instances.
      def self.pdftotext_path
        @@pdftotext_path
      end

      # Set location of the pdftotext executable for all instances.
      def self.pdftotext_path=(val)
        @@pdftotext_path = val
      end
    end
  end
end
