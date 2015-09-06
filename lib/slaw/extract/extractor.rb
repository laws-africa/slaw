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

      # Extract text from a file.
      #
      # @param filename [String] filename to extract from
      #
      # @return [String] extracted text
      def extract_from_file(filename)
        mimetype = get_mimetype(filename)

        case mimetype && mimetype.type
        when 'application/pdf'
          extract_from_pdf(filename)
        when 'text/plain', nil
          extract_from_text(filename)
        else
          text = extract_via_tika(filename)
          if text.empty? or text.nil?
            raise ArgumentError.new("Unsupported file type #{mimetype || 'unknown'}")
          end
          text
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
            return stdout
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
        File.read(filename)
      end

      # Extract text from +filename+ by sending it to apache tika
      # http://tika.apache.org/
      def extract_via_tika(filename)
        # the Yomu gem falls over when trying to write large amounts of data
        # the JVM stdin, so we manually call java ourselves, relying on yomu
        # to supply the gem
        require 'slaw/extract/yomu_patch'
        logger.info("Using Tika to get text from #{filename}. You need a JVM installed for this.")

        text = Yomu.text_from_file(filename)
        logger.info("Tika returned #{text.length} bytes")
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
