# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::ActGenerator do
  subject { Slaw::ActGenerator.new('za') }

  describe 'guess_section_number_after_title' do
    context 'section number after title' do
      it 'should work' do
        text = "
Section title
1. Section content

Another section title
2. Section content that is long.
"
        subject.guess_section_number_after_title(text).should be true
      end
    end

    context 'section number before title' do
      it 'should default to false' do
        subject.guess_section_number_after_title("").should be false
      end

      it 'should be false' do
        text = "
Mistaken title
1. Section title

Some content.

2. Second title

Some content.
"
        subject.guess_section_number_after_title(text).should be false
      end
    end
  end

  describe 'unparse' do
    it 'should escape keywards when unparsing' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <heading>Section</heading>
        <paragraph id="section-1.paragraph-0">
          <content>
            <p>Chapter 2 ignored</p>
            <p>Chapters</p>
            <p>Part 2 ignored</p>
            <p>participation</p>
            <p>Schedule 2 ignored</p>
            <p>Schedules</p>
            <p>HEADING x</p>
            <p>SUBHEADING x</p>
            <p>BODY not escaped</p>
            <p>BODY</p>
            <p>PREAMBLE not escaped</p>
            <p>PREAMBLE</p>
            <p>PREFACE not escaped</p>
            <p>PREFACE</p>
            <p>2. ignored</p>
            <p>2.1 ignored</p>
            <p>(2) ignored</p>
            <p>(a) ignored</p>
            <p>(2a) ignored</p>
            <p>{| ignored</p>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. Section

\\Chapter 2 ignored

Chapters

\\Part 2 ignored

participation

\\Schedule 2 ignored

Schedules

\\HEADING x

\\SUBHEADING x

BODY not escaped

\\BODY

PREAMBLE not escaped

\\PREAMBLE

PREFACE not escaped

\\PREFACE

\\2. ignored

\\2.1 ignored

\\(2) ignored

\\(a) ignored

\\(2a) ignored

\\{| ignored

'
    end

    it 'should escape inlines when unparsing' do
      doc = xml2doc(section(<<'XML'
        <num>1.</num>
        <heading>Section</heading>
        <paragraph id="section-1.paragraph-0">
          <content>
            <p>text \ with a single slash</p>
            <p>some <b>inlines // <ref href="#foo">with // slashes</ref></b></p>
            <p>inlines that ** should // be [[ escaped ![ and ]]</p>
            <p>refs <ref href="#foo">https://example.com with ] and ]( and <b>nested **</b></ref></p>
            <p>super <sup>with ^^</sup> and sub <sub>_^ with ^_</sub></p>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      # NOTE: in single quoted strings, backslash sequences aren't considered special, EXCEPT a double backslash
      # which is actually a single backslash. So \\ needs to be \\\\ while \* is just \*. The mind boggles.
      text.should == 'BODY

1. Section

text \\\\ with a single slash

some **inlines \/\/ [with \/\/ slashes](#foo)**

inlines that \*\* should \/\/ be \[\[ escaped \![ and \]\]

refs [https:\/\/example.com with ] and \]( and **nested \*\***](#foo)

super ^^with \^\^^^ and sub _^\_^ with \^_^_

'
    end

    it 'should escape listIntros when unparsing' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <heading>Section</heading>
        <paragraph id="section-9.paragraph-0">
          <content>
            <blockList id="section-9.paragraph-0.list1" renest="true">
              <listIntroduction>(2) A special meeting <remark>[ foo ]</remark>:</listIntroduction>
              <item id="section-9.paragraph-0.list1.a">
                <num>(a)</num>
                <p>the chairperson so directs; or</p>
              </item>
              <item id="section-9.paragraph-0.list1.b">
                <num>(b)</num>
                <p>a majority of the members</p>
              </item>
            </blockList>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. Section

\\(2) A special meeting [[ foo ]]:

(a) the chairperson so directs; or

(b) a majority of the members

'
    end

    it 'should unparse remarks correctly' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <paragraph id="section-19.paragraph-0">
          <content>
            <p>
              <remark status="editorial">[ foo ]</remark>
            </p>
            <p>Section 1 <remark status="editorial">[ foo ]</remark></p>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. 

[[ foo ]]

Section 1 [[ foo ]]

'
    end

    it 'should unparse refs correctly' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <paragraph id="section-19.paragraph-0">
          <content>
            <p>Hello <ref href="/za/act/123">there</ref> friend.</p>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. 

Hello [there](/za/act/123) friend.

'
    end

    it 'should unparse underlines correctly' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <paragraph id="section-19.paragraph-0">
          <content>
            <p>Hello <u>underlined</u>.</p>
          </content>
        </paragraph>
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. 

Hello __underlined__.

'
    end

    it 'should replace eol and br with newlines in tables' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <table eId="sec__21_table_1">
          <tr>
            <td>
              <p>foo<eol/>bar<br/>baz</p>
            </td>
            <td>
              <p>
              one<br/>two<eol/>three

              </p>
            </td>
          </tr>
        </table>'
XML
      ))

      text = subject.text_from_act(doc)
      text.should == 'BODY

1. 

{| 
|-
| foo
bar
baz
| 
              one
two
three

|-
|}

'
    end

    it 'should unparse schedules correctly' do
      doc = subject.generate_from_text(<<EOS
1. Something

SCHEDULE
HEADING First Schedule [[remark]]
SUBHEADING Subheading [[another]]

Subject to approval in terms of this By-Law.
EOS
)
      s = subject.text_from_act(doc)
      s.should == 'BODY

1. Something

SCHEDULE
HEADING First Schedule [[remark]]
SUBHEADING Subheading [[another]]

Subject to approval in terms of this By-Law.

'
    end
  end

  describe 'round trip' do
    it 'should be idempotent for escapes' do
      text = File.open('spec/fixtures/roundtrip-escapes.txt', 'r').read()
      act = subject.generate_from_text(text)
      xml = act.to_xml(encoding: 'utf-8')
      subject.text_from_act(act).should == text
    end
  end
end
