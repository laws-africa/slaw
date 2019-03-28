# Slaw [![Build Status](https://travis-ci.org/longhotsummer/slaw.svg)](http://travis-ci.org/longhotsummer/slaw)

Slaw is a lightweight library for generating Akoma Ntoso 2.0 Act XML from plain text documents.
It is used to power [Indigo](https://github.com/OpenUpSA/indigo) and uses grammars developed for the legal
traditions in these countries:

* South Africa
* Poland

Slaw allows you to:

1. parse plain text and transform it into an Akoma Ntoso Act XML document
2. unparse Akoma Ntoso XML into a plain-text format suitable for re-parsing

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

The simplest way to use Slaw is via the commandline:

    $ slaw parse myfile.text --grammar za

## Overview

Slaw generates Acts in the [Akoma Ntoso](http://www.akomantoso.org) 2.0 XML
standard for legislative documents. It first parses plain text using a grammar
and then generates XML from the resulting syntax tree.

Most by-laws in South Africa are available as PDF documents. You will therefore
need to extract the text from the PDF first, using a tool like pdftotext.
PDFs can product oddities (such as oddly wrapped lines) and Slaw has a number of
rules-of-thumb for correcting these. These rules are based on South African
by-laws and may not be suitable for all regions.

The grammar is expressed as a [Treetop](https://github.com/nathansobo/treetop/) grammar
and has been developed specifically for the format of South African acts and by-laws.
Grammars for other regions could de developed depending on the complexity of a region's
formats.

The grammar cannot catch some subtleties of an act or by-law -- such as nested list numbering --
so Slaw performs some post-processing on the XML produced by the parser. In particular,
it nests lists correctly.

## Parsing

Slaw uses Treetop to compile a grammar into a backtracking parser. The parser builds a parse
tree, the nodes of which know how to serialize themselves in XML format.

Supporting formats from other country's legal traditions probably requires creating a new grammar
and parser.

## Adding your own grammar

Slaw can dynamically load your custom Treetop grammars. When called with ``--grammar xy``, Slaw
tries to require `slaw/grammars/xy/act` and instantiate the parser class ``Slaw::Grammars::XY::ActParser``.
Slaw always uses the rule `act` as the root of the parser.

You can create your own grammar by creating a gem that provides these files and classes.

## Contributing

1. Fork it at http://github.com/longhotsummer/slaw/fork
2. Install dependencies: `bundle install`
3. Create your feature branch: `git checkout -b my-new-feature`
4. Write great code!
5. Run tests: `rspec`
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin my-new-feature`
8. Create a new Pull Request

## Changelog

### 3.0.0 (?)

* Inline bold and italics
* Support for CROSSHEADING elements using an empty hcontainer until we support AKN 3.0
* Support for LONGTITLE in PREFACE
* Remarks and references support nested inline elements
* BREAKING: `clauses` rule renamed to `inline_elements` so as not to clash with real AKN clauses
* BREAKING: `block_paragraphs` rule renamed to `generic_container` and adjusted to be singular to be simpler to understand
* BREAKING: un-numbered paragraph elements have new ids, that should not clash with numbered paragraphs from other grammars

### 2.2.0 (18 March 2019)

* Schedules use hcontainer, not article
* Schedules allow rich content in title and heading

### 2.1.0 (18 March 2019)

* Make subclassing preface statements easier

### 2.0.0 (15 March 2019)

* Remove support for PDFs. Do text extraction from PDFs outside of this library.
* Support dynamically loading grammars from other gems.
* Don't change ALL CAPS headings to Sentence Case.

### 1.0.4 (5 February 2019)

* SECURITY require Nokogiri 1.8.5 or greater to address https://nvd.nist.gov/vuln/detail/CVE-2018-14404

### 1.0.3 (26 September 2018)

* FIX bug in all grammars that dropped less-than symbols `<` from input text.

### 1.0.2 (2 June 2018)

* FIX bug in ZA grammar when parsing dotted numbered subsections ending with a newline

### 1.0.1

* Improved support for other legal traditions / grammars.
* Add Polish legal tradition grammar.
* Slaw no longer does too much introspection of a parsed document, since that can be so tradition-dependent.
* Move reformatting out of Slaw since it's tradition-dependent.
* Remove definition linking, Slaw no longer supports it.
* Remove unused code for interacting with the internals of acts.

### 0.17.2

* Match defined terms in 'definition' section.
* Updated nokogiri dependency to 1.8.2

### 0.17.0

* Support links and images inside tables, by parsing tables natively.

### 0.16.0

* Support --crop for PDFs. Requires [poppler](https://poppler.freedesktop.org/) pdftotex, not xpdf.

### 0.15.2

* Update nokogiri to ~> 1.8.1

### 0.15.1

* Ignore non-AKN compatible table attributes

### 0.15.0

* Support tables in many non-PDF documents (eg. Word documents) by converting to HTML and then to Akoma Ntoso

### 0.14.2

* Convert non-breaking space (\xA0) to space

### 0.14.1

* Support links in remarks

### 0.14.0

* Support inline image tags, using Markdown syntax: \![alt text](image url)
* Smarter un-break lines

### 0.13.0

* FIX allow Schedule, Part and other headings at the start of blocklist and subsections
* FIX replace empty CONTENT elements with empty P tags so XML validates
* Better handling of empty subsections and blocklist items

### 0.12.0

* Support links/references using Markdown-like \[text](href) syntax.
* FIX allow remarks in blocklist items

### 0.11.0

* Support newlines in table cells as EOL (or BR in HTML)
* FIX unparsing of remarks, introduced in 0.10.0

### 0.10.1

* Ensure backslash escaping handles listIntroductions and partial words correctly

### 0.10.0

* New command `unparse FILE` which transforms an Akoma Ntoso XML document into plain text, suitable for re-parsing
* Support escaping special words with a backslash

### 0.9.0

* This release makes reasonably significant changes to generated XML, particularly
  for sections without explicit subsections.
* Blocklists with (aa) following (z) are using the same numbering format.
* Change how blockList listIntroduction elements are created to be more generic
* Support for sections that dive straight into lists without subsections
* Simplify grammar
* Fix elements with potentially duplicate ids

### 0.8.3

* During cleanup, break lines on section titles that don't have a space after the number, eg: "New section title 4.(1) The content..."

### 0.8.2

* Schedules can be empty (#10)

### 0.8.1

* Schedules can have both a title and a heading, permitting schedules titled "First Schedule" and not just "Schedule 1"

### 0.8.0

* FEATURE: parse command only reformats input for PDFs or when --reformat is given
* FIX: don't error on defn tags without link to defined term

### 0.7.4

* use refersTo to identify blocks containing term definitions, rather than setting an (invalid) ID

### 0.7.3

* add link-definitions command to find and extract defined terms and link them to their definitions
* exit with non-zero exit code on failure (see https://github.com/erikhuda/thor/issues/244)

### 0.7.2

* add --section-number-position argument to slaw command
* grammar supports empty chapters and parts

### 0.7.1

* major changes to grammar to permit chapters, parts, sections etc. in schedules
