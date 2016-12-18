# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::ActGenerator do
  describe 'guess_section_number_after_title' do
    context 'section number after title' do
      it 'should work' do
        text = "
Section title
1. Section content

Another section title
2. Section content that is long.
"
        subject.guess_section_number_after_title(text).should be_true
      end
    end

    context 'section number before title' do
      it 'should default to false' do
        subject.guess_section_number_after_title("").should be_false
      end

      it 'should be false' do
        text = "
Mistaken title
1. Section title

Some content.

2. Second title

Some content.
"
        subject.guess_section_number_after_title(text).should be_false
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
      text.should == '1. Section

\Chapter 2 ignored

Chapters

\Part 2 ignored

participation

\Schedule 2 ignored

Schedules

BODY not escaped

\BODY

PREAMBLE not escaped

\PREAMBLE

PREFACE not escaped

\PREFACE

\2. ignored

\2.1 ignored

\(2) ignored

\(a) ignored

\(2a) ignored

\{| ignored

'
    end

    it 'should escape listIntros when unparsing' do
      doc = xml2doc(section(<<XML
        <num>1.</num>
        <heading>Section</heading>
        <paragraph id="section-9.paragraph-0">
          <content>
            <blockList id="section-9.paragraph-0.list1">
              <listIntroduction>(2) A special meeting:</listIntroduction>
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
      text.should == '1. Section

\(2) A special meeting:

(a) the chairperson so directs; or

(b) a majority of the members

'
    end
  end
end
