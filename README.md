# Slaw [![Build Status](https://travis-ci.org/longhotsummer/slaw.svg)](http://travis-ci.org/longhotsummer/slaw)

Slaw is a lightweight library for generating and rendering Akoma Ntoso 2.0 Act XML from plain text and PDF documents.
It is used to power [openbylaws.org.za](http://openbylaws.org.za) and [steno.openbylaws.org.za](http://steno.openbylaws.org.za)
and uses grammars developed for South African acts and by-laws.

Slaw allows you to:

1. extract plain text from PDFs and clean up that text
2. parse plain text and transform it into an Akoma Ntoso Act XML document
3. render the XML document into HTML

Slaw is lightweight because it wraps around a Nokogiri XML representation of
the parsed document. It provides some support methods for manipulating these
documents, but anything advanced must manipulate the XML directly.

## Installation

Add this line to your application's Gemfile:

    gem 'slaw'

And then execute:

    $ bundle

Or install it with:

    $ gem install slaw

To run PDF extraction you will also need [xpdf](http://www.foolabs.com/xpdf/).
If you're on a Mac, you can use:

    brew install xpdf

## Overview

Slaw generates Acts in the [Akoma Ntoso](http://www.akomantoso.org) 2.0 XML
standard for legislative documents. It first parses plain text using a grammar
and then generates XML from the resulting syntax tree.

Most by-laws in South Africa are available as PDF documents. Slaw therefore has support
for extracting and cleaning up text from PDFs before parsing it. Extracting text from
PDFs can product oddities (such as oddly wrapped lines) and Slaw has a number of
rules-of-thumb for correcting these. These rules are based on South African
by-laws and may not be suitable for all regions.

The grammar is expressed as a [Treetop](https://github.com/nathansobo/treetop/) grammar
and has been developed specifically for the format of South African acts and by-laws.
Grammars for other regions could de developed depending on the complexity of a region's
formats.

The grammar cannot catch some subtleties of an act or by-law -- such as nested list numbering --
so Slaw performs some post-processing on the XML produced by the parser. In particular,
it nests lists correctly and looks for specially defined terms and their occurrences in the document.

## Quick Start

Install the gem using

    gem install slaw

Extract text from a PDF and parse it as a South African by-law:

```ruby
require 'slaw'

# extract text from a PDF file and clean it up
extractor = Slaw::Extract::Extractor.new
text = extractor.extract_from_pdf('/path/to/file.pdf')

# parse the text into a XML and
generator = Slaw::ZA::ByLawGenerator.new
bylaw = generator.generate_from_text(text)
puts bylaw.to_xml(indent: 2)

# render the by-law as HTML, using / as the root
# for relative URLs
renderer = Slaw::Render::HTMLRenderer.new
puts renderer.render(bylaw.doc, '/')
```

## Extraction

Extraction is done by the `Slaw::Extract::Extractor` class. It currently handles
PDF and plain text files. Slaw uses `pdftotext` from the `xpdf` package to extract
the plain text from PDFs. PDFs are great for presentation, but suck for accurately storing
text. As a result, the extraction can produce oddities, such as lines broken in weird
places (or not broken when they should be). Slaw gets around this by running
some cleanup routines on the extracted text.

For example, it knows that these lines:

    (b) any wall, swimming pool, reservoir or bridge
    or any other structure connected therewith; (c) any fuel pump or any
    tank used in connection therewith

should probably be broken at the section numbers:

    (b) any wall, swimming pool, reservoir or bridge or any other structure connected therewith;
    (c) any fuel pump or any tank used in connection therewith

If your region's numbering format differs significantly from this, these rules might not work.

Some other steps Slaw takes after extraction include (check `Slaw::Parse::Cleanser` for the full set):

* changing newlines to `\n`, and normalising quotation characters
* removing page numbers and other boilerplate
* stripping the table of contents (we can generate our own from the parsed document)
* changing tabs to spaces, stripping leading and trailing spaces and removing blank lines

## Parsing

Slaw uses Treetop to compile a grammar into a backtracking parser. The parser builds a parse
tree, each node of which knows how to serialize itself in XML format.

While most South African by-laws are superficially very similar, there are a sufficient differences
in their typesetting to make parsing them difficult. The grammar handles most
edge cases but may not catch them all. The one thing it cannot yet detect well is the difference
between section titles before and after a section number:

    1. Definitions
    In this by-law, the following words ...

    Definitions
    1. In this by-law, the following words ...

This must be set by the user before parsing.

The parser does its best not to choke on input it doesn't understand, preferring a best effort
to a completely accurate result. For example it may not be able to work out a section heading
and so will treat it as simply another statement in the previous section. This causes the parser
to use a lot of backtracking and negative lookahead assertions, which can be slow for large documents.

The grammar supports a number of subsection numbering formats, which are often mixed
in a document to indicate different levels of nesting.

    (a)
    (2)
    (3b)
    (ii)
    3.4

During post-processing it works out how to nest these appropriately.

For more information see the South African by-law grammar at
[lib/slaw/za/bylaw.treetop](lib/slaw/za/bylaw.treetop) and the list nesting
at [lib/slaw/parse/blocklists.rb](lib/slaw/parse/blocklists.rb).

## Rendering

Slaw renders XML to HTML using XSLT. For the most part there is a direct mapping between
Akoma Ntoso structure and the HTML layout, so most AN nodes are simply mapped to `div` or `span`
elements with a class attribute derived from the name of the AN element and an ID element taken
from the node, if any. This makes it both fast and flexible, since it's easy to
apply layout rules with CSS.

Slaw can render either an entire document like this, or just a portion of the XML tree.

## Meta-data

Acts and by-laws have metadata which it is not possible to get from their plain text representations,
such as their title, date and format of publication or act number. Slaw provides some helpers
for manipulating this meta-data. For example,

```ruby
bylaw = Slaw::ByLaw.new('spec/fixtures/community-fire-safety.xml')
print bylaw.id_uri
bylaw.title = 'A new title'
bylaw.name = 'a-new-title'
bylaw.published!(date: '2014-09-28')
print bylaw.id_uri
```

## Schedules

South African acts and by-laws can have addendums called schedules. They are technically a part of
the act but are not part of the primary body and have more relaxed formatting. Slaw finds schedules
by looking for section headings, but makes no effort to capture the format of their contents.

Akoma Ntoso has no explicit support for schedules. Instead, Slaw stores all schedules under a single
Akoma Ntoso `component` elements at the end of the XML document, with a name of `schedules`.

## Contributing

1. Fork it at http://github.com/longhotsummer/slaw/fork
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
