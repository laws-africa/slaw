# Slaw [![Build Status](https://travis-ci.org/longhotsummer/slaw.svg)](http://travis-ci.org/longhotsummer/slaw)

Slaw is a lightweight library for rendering and generating Akoma Ntoso acts from plain text and PDF documents.
It is used to power [openbylaws.org.za](http://openbylaws.org.za).

## Installation

Add this line to your application's Gemfile:

    gem 'slaw'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install slaw

## Usage

TODO: Write usage instructions here

### Extracting text from PDFs

You will need [xpdf](http://www.foolabs.com/xpdf/) to run PDF extraction. If you're
on a Mac you can use

    brew install xpdf

Extracting PDFs often break lines in odd places (or doesn't break them when it should). Slaw gets around
this by running some cleanup routines on the extracted text.

```ruby
extractor = Slaw::Extract::Extractor.new

# to guess the filetype by extension
text = extractor.extract_from_file('/path/to/file.pdf')

# or if you know it's a PDF
text = extractor.extract_from_pdf('/path/to/file.pdf')

# You can also "extract" text from a plain-text file
text = extractor.extract_from_text('/path/to/file.txt')
```

## Contributing

1. Fork it at http://github.com/longhotsummer/slaw/fork
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
