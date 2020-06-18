# encoding: UTF-8

require 'slaw'
require 'slaw/grammars/za/act_nodes'

describe Slaw::ActGenerator do
  subject { Slaw::ActGenerator.new('za') }

  def parse(rule, s)
    subject.builder.text_to_syntax_tree(s, {root: rule})
  end

  def should_parse(rule, s)
    s << "\n" unless s.end_with?("\n")
    tree = subject.builder.text_to_syntax_tree(s, {root: rule})

    if not tree
      raise Exception.new(subject.failure_reason || "Couldn't match to grammar") if tree.nil?
    else
      # count an assertion
      tree.should_not be_nil
    end
  end

  def to_xml(node, *args)
    b = ::Nokogiri::XML::Builder.new
    node.to_xml(b, *args)
    b.doc.root.to_xml(encoding: 'UTF-8')
  end

  before(:each) do
    Slaw::Grammars::Counters.reset!
  end

  #-------------------------------------------------------------------------------
  # General body

  describe 'body' do
    it 'should handle general content before sections' do
      node = parse :body, <<EOS
Some content before the section

1. Section
Hello there

CROSSHEADING crossheading
EOS
      to_xml(node).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>Some content before the section</p>
    </content>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
    <hcontainer eId="sec_1__hcontainer_2" name="crossheading">
      <heading>crossheading</heading>
    </hcontainer>
  </section>
</body>'
    end

    it 'should handle blocklists before sections' do
      node = parse :body, <<EOS
Some content before the section

(a) foo
(b) bar

CROSSHEADING crossheading

1. Section
Hello there

CROSSHEADING crossheading
EOS
      to_xml(node).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>Some content before the section</p>
      <blockList eId="hcontainer_1__list_1" renest="true">
        <item eId="hcontainer_1__list_1__item_a">
          <num>(a)</num>
          <p>foo</p>
        </item>
        <item eId="hcontainer_1__list_1__item_b">
          <num>(b)</num>
          <p>bar</p>
        </item>
      </blockList>
    </content>
  </hcontainer>
  <hcontainer eId="hcontainer_2" name="crossheading">
    <heading>crossheading</heading>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
    <hcontainer eId="sec_1__hcontainer_2" name="crossheading">
      <heading>crossheading</heading>
    </hcontainer>
  </section>
</body>'
    end

    it 'should handle escaped content' do
      node = parse :body, <<EOS
\\1. ignored

\\CROSSHEADING crossheading

1. Section
\\Chapter 2 ignored
EOS
      to_xml(node).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>1. ignored</p>
      <p>CROSSHEADING crossheading</p>
    </content>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Chapter 2 ignored</p>
      </content>
    </hcontainer>
  </section>
</body>'
    end

    it 'should understand a body marker' do
      node = parse :body, <<EOS
BODY

Some content before the section

1. Section
Hello there
EOS
      to_xml(node).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>Some content before the section</p>
    </content>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</body>'
    end

    it 'should handle no body and a schedule' do
      node = parse :act, <<EOS
this is in the preface

SCHEDULE

some stuff
EOS

      b = ::Nokogiri::XML::Builder.new
      b.root do |b|
        node.to_xml(b)
      end
      xml = b.to_xml(encoding: 'UTF-8')

      xml.should include('<body/>')
    end

    it 'should handle an empty body' do
      node = parse :body, <<EOS
EOS

      to_xml(node).should == '<body/>'
    end
  end

  #-------------------------------------------------------------------------------
  # Chapters
  #
  describe 'chapters' do
    it 'should handle chapter headers' do
      node = parse :chapter, <<EOS
ChaPTEr 2 - 
The Chapter Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle chapters without titles' do
      node = parse :chapter, <<EOS
ChaPTEr 2:

1. Section
Hello there
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle general content at the start of a chapter' do
      node = parse :chapter, <<EOS
Chapter 2
The Chapter Heading

CROSSHEADING crossheading

Some lines at the start of the chapter.
EOS
      node.num.should == "2"
      node.heading.heading.text_value.should == "\nThe Chapter Heading"
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <hcontainer eId="chp_2__hcontainer_1" name="crossheading">
    <heading>crossheading</heading>
  </hcontainer>
  <hcontainer eId="chp_2__hcontainer_2" name="hcontainer">
    <content>
      <p>Some lines at the start of the chapter.</p>
    </content>
  </hcontainer>
</chapter>'
    end

    it 'should handle general content at the start of a chapter with other content' do
      node = parse :chapter, <<EOS
Chapter 2 - The Chapter Heading

Some lines at the start of the chapter.

1. Section 1

Section text.
EOS
      node.num.should == "2"
      node.heading.heading.text_value.should == 'The Chapter Heading'
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <hcontainer eId="chp_2__hcontainer_1" name="hcontainer">
    <content>
      <p>Some lines at the start of the chapter.</p>
    </content>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section 1</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Section text.</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle whitespace in chapter titles' do
      node = parse :chapter, <<EOS
Chapter 2
  The Chapter Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle inlines in chapter titles after newline' do
      node = parse :chapter, <<EOS
Chapter 2
  The **Chapter** [Heading](/za/act/1990/1) [[remark]]

1. Section
Hello there
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The <b>Chapter</b> <ref href="/za/act/1990/1">Heading</ref> <remark status="editorial">[remark]</remark></heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle inlines in chapter titles' do
      node = parse :chapter, <<EOS
Chapter 2 -  The **Chapter** [Heading](/za/act/1990/1) [[remark]]

1. Section
Hello there
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The <b>Chapter</b> <ref href="/za/act/1990/1">Heading</ref> <remark status="editorial">[remark]</remark></heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</chapter>'
    end

    it 'should handle empty chapters' do
      node = parse :body, <<EOS
Chapter 2 The Chapter Heading
Chapter 3 The Other Heading
EOS
      to_xml(node).should == '<body>
  <chapter eId="chp_2">
    <num>2</num>
    <heading>The Chapter Heading</heading>
  </chapter>
  <chapter eId="chp_3">
    <num>3</num>
    <heading>The Other Heading</heading>
  </chapter>
</body>'
    end

    it 'should be able to contain just a table' do
      node = parse :chapter, <<EOS
Chapter 2 The Chapter

{|
| foo
|}
EOS
      to_xml(node).should == '<chapter eId="chp_2">
  <num>2</num>
  <heading>The Chapter</heading>
  <hcontainer eId="chp_2__hcontainer_1" name="hcontainer">
    <content>
      <table eId="chp_2__hcontainer_1__table_1">
        <tr>
          <td>
            <p>foo</p>
          </td>
        </tr>
      </table>
    </content>
  </hcontainer>
</chapter>'
    end

    it 'should ignore escaped chapter headers' do
      node = parse :chapter, <<EOS
Chapter 1 The Chapter

Stuff

\\Chapter 2 - Ignored

More stuff
EOS
      to_xml(node).should == '<chapter eId="chp_1">
  <num>1</num>
  <heading>The Chapter</heading>
  <hcontainer eId="chp_1__hcontainer_1" name="hcontainer">
    <content>
      <p>Stuff</p>
      <p>Chapter 2 - Ignored</p>
      <p>More stuff</p>
    </content>
  </hcontainer>
</chapter>'
    end

    it 'should allow parts in chapters' do
      node = parse :chapter, <<EOS
Chapter 1 - Chapter One

Part 1 - Chapter One Part One

one-one

Part 2 - Chapter One Part Two

one-two
EOS
      to_xml(node).should == '<chapter eId="chp_1">
  <num>1</num>
  <heading>Chapter One</heading>
  <part eId="chp_1__part_1">
    <num>1</num>
    <heading>Chapter One Part One</heading>
    <hcontainer eId="chp_1__part_1__hcontainer_1" name="hcontainer">
      <content>
        <p>one-one</p>
      </content>
    </hcontainer>
  </part>
  <part eId="chp_1__part_2">
    <num>2</num>
    <heading>Chapter One Part Two</heading>
    <hcontainer eId="chp_1__part_2__hcontainer_1" name="hcontainer">
      <content>
        <p>one-two</p>
      </content>
    </hcontainer>
  </part>
</chapter>'
    end
  end

  #-------------------------------------------------------------------------------
  # Parts

  describe 'parts' do
    it 'should handle part headers' do
      node = parse :part, <<EOS
pART 2
The Part Heading

CROSSHEADING crossheading

1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <hcontainer eId="part_2__hcontainer_1" name="crossheading">
    <heading>crossheading</heading>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers with dashes' do
      node = parse :part, <<EOS
Part 2 - The Part Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers with colons' do
      node = parse :part, <<EOS
Part 2: The Part Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers without titles' do
      node = parse :part, <<EOS
Part 2:

1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers with whitespace' do
      node = parse :part, <<EOS
Part 2
  The Part Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers with inline elements after newline' do
      node = parse :part, <<EOS
Part 2
  The **Part** Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The <b>Part</b> Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle part headers with inline elements' do
      node = parse :part, <<EOS
Part 2 The **Part** Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The <b>Part</b> Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle parts and odd section numbers' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :parts, <<EOS
PART 1
PREVENTION AND SUPPRESSION OF HEALTH NUISANCES
1.
No owner or occupier of any shop or business premises or vacant land adjoining a shop or business premises shall cause a health nuisance.
EOS
      to_xml(node).should == '<part eId="part_1">
  <num>1</num>
  <heading>PREVENTION AND SUPPRESSION OF HEALTH NUISANCES</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading/>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>No owner or occupier of any shop or business premises or vacant land adjoining a shop or business premises shall cause a health nuisance.</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end
    
    it 'should handle general content after the part heading' do
      node = parse :part, <<EOS
Part 2
The Part Heading

Some text before the part.

1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.heading.text_value.should == "\nThe Part Heading"
      to_xml(node).should == '<part eId="part_2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <hcontainer eId="part_2__hcontainer_1" name="hcontainer">
    <content>
      <p>Some text before the part.</p>
    </content>
  </hcontainer>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</part>'
    end

    it 'should handle empty parts' do
      node = parse :body, <<EOS
Part 2 The Part Heading
Part 3 The Other Heading
EOS
      to_xml(node).should == '<body>
  <part eId="part_2">
    <num>2</num>
    <heading>The Part Heading</heading>
  </part>
  <part eId="part_3">
    <num>3</num>
    <heading>The Other Heading</heading>
  </part>
</body>'
    end

    it 'should handle escaped parts' do
      node = parse :body, <<EOS
Part 2 The Part Heading
\\Part 3 ignored
EOS
      to_xml(node).should == '<body>
  <part eId="part_2">
    <num>2</num>
    <heading>The Part Heading</heading>
    <hcontainer eId="part_2__hcontainer_1" name="hcontainer">
      <content>
        <p>Part 3 ignored</p>
      </content>
    </hcontainer>
  </part>
</body>'
    end

    it 'should allow chapters in parts' do
      node = parse :part, <<EOS
Part 1 - Part One

Chapter 1 - Part One Chapter One

one-one

Chapter 2 - Part One Chapter Two

one-two
EOS
      to_xml(node).should == '<part eId="part_1">
  <num>1</num>
  <heading>Part One</heading>
  <chapter eId="part_1__chp_1">
    <num>1</num>
    <heading>Part One Chapter One</heading>
    <hcontainer eId="part_1__chp_1__hcontainer_1" name="hcontainer">
      <content>
        <p>one-one</p>
      </content>
    </hcontainer>
  </chapter>
  <chapter eId="part_1__chp_2">
    <num>2</num>
    <heading>Part One Chapter Two</heading>
    <hcontainer eId="part_1__chp_2__hcontainer_1" name="hcontainer">
      <content>
        <p>one-two</p>
      </content>
    </hcontainer>
  </chapter>
</part>'
    end
  end

  #-------------------------------------------------------------------------------
  # Subparts

  describe 'subparts' do
    it 'should handle subparts' do
      node = parse :subpart, <<EOS
SUBPART 2 - Heading

1. Section
Hello there
EOS
      to_xml(node).should == '<subpart eId="subpart_2">
  <num>2</num>
  <heading>Heading</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</subpart>'
    end

    it 'should handle subparts in parts' do
      node = parse :part, <<EOS
PART A - The Part

SUBPART 1 - The Subpart 1

1. Section

Hello

SUBPART 2 - The Subpart 2

2. Section

Bye
EOS
      to_xml(node).should == '<part eId="part_A">
  <num>A</num>
  <heading>The Part</heading>
  <subpart eId="part_A__subpart_1">
    <num>1</num>
    <heading>The Subpart 1</heading>
    <section eId="sec_1">
      <num>1.</num>
      <heading>Section</heading>
      <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
        <content>
          <p>Hello</p>
        </content>
      </hcontainer>
    </section>
  </subpart>
  <subpart eId="part_A__subpart_2">
    <num>2</num>
    <heading>The Subpart 2</heading>
    <section eId="sec_2">
      <num>2.</num>
      <heading>Section</heading>
      <hcontainer eId="sec_2__hcontainer_1" name="hcontainer">
        <content>
          <p>Bye</p>
        </content>
      </hcontainer>
    </section>
  </subpart>
</part>'
    end

    it 'should allow optional numbers' do
      node = parse :subpart, <<EOS
SUBPART - Heading - with a dash

1. Section
Hello there
EOS
      to_xml(node).should == '<subpart eId="subpart_1">
  <heading>Heading - with a dash</heading>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>Hello there</p>
      </content>
    </hcontainer>
  </section>
</subpart>'
    end
  end

  #-------------------------------------------------------------------------------
  # Subsections

  describe 'subsection' do
    it 'should handle basic subsections' do
      should_parse :subsection, <<EOS
        (2) foo bar
EOS
    end

    it 'should handle a blocklist' do
      node = parse :subsection, <<EOS
        (2) title
        (a) one
        (b) two
        (c) three
        (i) four
EOS
      to_xml(node, "", 1).should == '<subsection eId="subsec_2">
  <num>(2)</num>
  <content>
    <p>title</p>
    <blockList eId="subsec_2__list_1" renest="true">
      <item eId="subsec_2__list_1__item_a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item eId="subsec_2__list_1__item_b">
        <num>(b)</num>
        <p>two</p>
      </item>
      <item eId="subsec_2__list_1__item_c">
        <num>(c)</num>
        <p>three</p>
      </item>
      <item eId="subsec_2__list_1__item_i">
        <num>(i)</num>
        <p>four</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    it 'should handle a subsection that dives straight into a list' do
      node = parse(:subsection, <<EOS
        (1) (a) one
        (b) two
        (c) three
        (i) four
EOS
                  )
      to_xml(node, "", 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <blockList eId="subsec_1__list_1" renest="true">
      <item eId="subsec_1__list_1__item_a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item eId="subsec_1__list_1__item_b">
        <num>(b)</num>
        <p>two</p>
      </item>
      <item eId="subsec_1__list_1__item_c">
        <num>(c)</num>
        <p>three</p>
      </item>
      <item eId="subsec_1__list_1__item_i">
        <num>(i)</num>
        <p>four</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    it 'should handle a subsection that is empty and dives straight into a list' do
      node = parse(:subsection, <<EOS
        (1)
        (a) one
        (b) two
EOS
                  )
      to_xml(node, "", 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <blockList eId="subsec_1__list_1" renest="true">
      <item eId="subsec_1__list_1__item_a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item eId="subsec_1__list_1__item_b">
        <num>(b)</num>
        <p>two</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    it 'should handle empty subsections' do
      node = parse(:section, <<EOS
        1. Section
        (1)
        (2)
        next line
        (3) third
EOS
                  )
      to_xml(node).should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection eId="sec_1__subsec_1">
    <num>(1)</num>
    <content>
      <p/>
    </content>
  </subsection>
  <subsection eId="sec_1__subsec_2">
    <num>(2)</num>
    <content>
      <p>next line</p>
    </content>
  </subsection>
  <subsection eId="sec_1__subsec_3">
    <num>(3)</num>
    <content>
      <p>third</p>
    </content>
  </subsection>
</section>'
    end

    it 'should handle a blocklist that dives straight into another list' do
      node = parse(:subsection, <<EOS
        (1) here's my really cool list,
        (a) one
        (b) (i) single
        (ii) double
EOS
                  )
      to_xml(node, "", 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <p>here\'s my really cool list,</p>
    <blockList eId="subsec_1__list_1" renest="true">
      <item eId="subsec_1__list_1__item_a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item eId="subsec_1__list_1__item_b">
        <num>(b)</num>
        <p/>
      </item>
      <item eId="subsec_1__list_1__item_i">
        <num>(i)</num>
        <p>single</p>
      </item>
      <item eId="subsec_1__list_1__item_ii">
        <num>(ii)</num>
        <p>double</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    it 'should handle a blocklist with empty elements' do
      node = parse(:subsection, <<EOS
        (1) here's my really cool list,
        (a)
        (b) (i) single
        (ii) double
EOS
                  )
      to_xml(node, "", 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <p>here\'s my really cool list,</p>
    <blockList eId="subsec_1__list_1" renest="true">
      <item eId="subsec_1__list_1__item_a">
        <num>(a)</num>
        <p/>
      </item>
      <item eId="subsec_1__list_1__item_b">
        <num>(b)</num>
        <p/>
      </item>
      <item eId="subsec_1__list_1__item_i">
        <num>(i)</num>
        <p>single</p>
      </item>
      <item eId="subsec_1__list_1__item_ii">
        <num>(ii)</num>
        <p>double</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    context 'dotted numbers' do
      it 'should handle dotted number subsection numbers' do
        node = parse :subsection, <<EOS
          9.9. foo
EOS
        node.num.should == "9.9"

        node = parse :subsection, <<EOS
          9.9 foo
EOS
        node.num.should == "9.9"
      end

      it 'should handle dotted number and letter subsection numbers' do
        node = parse :subsection, <<EOS
          9.9A. foo
EOS
        node.num.should == "9.9A"

        node = parse :subsection, <<EOS
          9.9bis foo
EOS
        node.num.should == "9.9bis"

        node = parse :subsection, <<EOS
          9.9A foo
EOS
        node.num.should == "9.9A"
      end

      it 'should handle dotted number sublists' do
        node = parse(:subsection, <<EOS
          9.9 foo
          9.9.1 item1
          9.9.2 item2
          9.9.2.1 item3
EOS
                    )
        to_xml(node, '', 1).should == '<subsection eId="subsec_9-9">
  <num>9.9</num>
  <content>
    <p>foo</p>
    <blockList eId="subsec_9-9__list_1" renest="true">
      <item eId="subsec_9-9__list_1__item_9-9-1">
        <num>9.9.1</num>
        <p>item1</p>
      </item>
      <item eId="subsec_9-9__list_1__item_9-9-2">
        <num>9.9.2</num>
        <p>item2</p>
      </item>
      <item eId="subsec_9-9__list_1__item_9-9-2-1">
        <num>9.9.2.1</num>
        <p>item3</p>
      </item>
    </blockList>
  </content>
</subsection>'
      end
    end

    it 'should id blocklists correctly' do
      node = parse(:subsection, <<EOS
        (1) a list
        (a) item 1
        (b) item 2
        some text
        (c) item 3
        (d) item 4
EOS
      )

      to_xml(node, '', 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <p>a list</p>
    <blockList eId="subsec_1__list_1" renest="true">
      <item eId="subsec_1__list_1__item_a">
        <num>(a)</num>
        <p>item 1</p>
      </item>
      <item eId="subsec_1__list_1__item_b">
        <num>(b)</num>
        <p>item 2</p>
      </item>
    </blockList>
    <p>some text</p>
    <blockList eId="subsec_1__list_2" renest="true">
      <item eId="subsec_1__list_2__item_c">
        <num>(c)</num>
        <p>item 3</p>
      </item>
      <item eId="subsec_1__list_2__item_d">
        <num>(d)</num>
        <p>item 4</p>
      </item>
    </blockList>
  </content>
</subsection>'
    end

    it 'should ignore escaped items' do
      node = parse(:subsection, <<EOS
        (1) a subsection
        \\(1) ignored
        \\9.9.2 item2
        \\some text
        \\(d) item 4
        \\(b) (i) single
EOS
      )

      to_xml(node, '', 1).should == '<subsection eId="subsec_1">
  <num>(1)</num>
  <content>
    <p>a subsection</p>
    <p>(1) ignored</p>
    <p>9.9.2 item2</p>
    <p>some text</p>
    <p>(d) item 4</p>
    <p>(b) (i) single</p>
  </content>
</subsection>'
    end

    it 'should ignore block elements mid-subsection' do
      node = parse :body, <<EOS
1. Section

(2) Schedule 1 is cool.
(3) Part 1
EOS
      to_xml(node).should == '<body>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <subsection eId="sec_1__subsec_2">
      <num>(2)</num>
      <content>
        <p>Schedule 1 is cool.</p>
      </content>
    </subsection>
    <subsection eId="sec_1__subsec_3">
      <num>(3)</num>
      <content>
        <p>Part 1</p>
      </content>
    </subsection>
  </section>
</body>'
    end
  end

  #-------------------------------------------------------------------------------
  # Numbered statements

  describe 'numbered_statement' do
    it 'should handle basic numbered statements' do
      should_parse :subsection, '(1) foo bar'
      should_parse :subsection, '(1a) foo bar'
    end
  end

  #-------------------------------------------------------------------------------
  # Preface

  context 'preface' do
    it 'should consider any text at the start to be preface' do
      node = parse :act, <<EOS
foo
bar
(1) stuff
(2) more stuff
baz
1. Section
(1) hello
EOS

      node.preface.text_value.should == "foo
bar
(1) stuff
(2) more stuff
baz
"
      to_xml(node.preface).should == '<preface>
  <p>foo</p>
  <p>bar</p>
  <p>(1) stuff</p>
  <p>(2) more stuff</p>
  <p>baz</p>
</preface>'

      today = Time.now.strftime('%Y-%m-%d')
      to_xml(node, "").should == '<act contains="originalVersion" name="act">
  <meta>
    <identification source="#slaw">
      <FRBRWork>
        <FRBRthis value="/za/act/1980/01/main"/>
        <FRBRuri value="/za/act/1980/01"/>
        <FRBRalias value="Short Title" name="title"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRcountry value="za"/>
      </FRBRWork>
      <FRBRExpression>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRlanguage language="eng"/>
      </FRBRExpression>
      <FRBRManifestation>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="' + today + '" name="Generation"/>
        <FRBRauthor href="#slaw"/>
      </FRBRManifestation>
    </identification>
    <references source="#this">
      <TLCOrganization eId="slaw" href="https://github.com/longhotsummer/slaw" showAs="Slaw"/>
      <TLCOrganization eId="council" href="/ontology/organization/za/council" showAs="Council"/>
    </references>
  </meta>
  <preface>
    <p>foo</p>
    <p>bar</p>
    <p>(1) stuff</p>
    <p>(2) more stuff</p>
    <p>baz</p>
  </preface>
  <body>
    <section eId="sec_1">
      <num>1.</num>
      <heading>Section</heading>
      <subsection eId="sec_1__subsec_1">
        <num>(1)</num>
        <content>
          <p>hello</p>
        </content>
      </subsection>
    </section>
  </body>
</act>'
    end

    it 'should support an optional preface' do
      node = parse :act, <<EOS
PREFACE
foo
1. Section
(1) hello
EOS

      node.preface.text_value.should == "PREFACE\nfoo\n"
      to_xml(node.preface).should == '<preface>
  <p>foo</p>
</preface>'
    end

    it 'should ignore escaped preface' do
      node = parse :act, <<EOS
\\PREFACE
1. Section
(1) hello
EOS

      to_xml(node.preface).should == '<preface>
  <p>PREFACE</p>
</preface>'
    end

    it 'should support remarks in the preface' do
      node = parse :act, <<EOS
PREFACE

[[remark]]

foo

[[ another remark]]

1. Section
(1) hello
EOS

      to_xml(node.preface).should == '<preface>
  <p>
    <remark status="editorial">[remark]</remark>
  </p>
  <p>foo</p>
  <p>
    <remark status="editorial">[ another remark]</remark>
  </p>
</preface>'
    end

    it 'should support no preface' do
      node = parse :act, <<EOS
1. Section
bar
EOS

      node.preface.text_value.should == ""
    end

    it 'should support prefaces and preambles' do
      node = parse :act, <<EOS
this is in the preface

PREAMBLE

this is in the preamble

1. Section
(1) hello
EOS

      to_xml(node.preface).should == '<preface>
  <p>this is in the preface</p>
</preface>'
      to_xml(node.preamble).should == '<preamble>
  <p>this is in the preamble</p>
</preamble>'
    end

    it 'should support explicit preface and preamble' do
      node = parse :act, <<EOS
PREFACE
this is in the preface

PREAMBLE
this is in the preamble

1. Section
(1) hello
EOS

      to_xml(node.preface).should == '<preface>
  <p>this is in the preface</p>
</preface>'
      to_xml(node.preamble).should == '<preamble>
  <p>this is in the preamble</p>
</preamble>'
    end

    it 'should obey a BODY marker' do
      node = parse :act, <<EOS
PREFACE
this is in the preface

PREAMBLE
this is in the preamble

BODY
this is in the body
EOS

      to_xml(node.preface).should == '<preface>
  <p>this is in the preface</p>
</preface>'
      to_xml(node.preamble).should == '<preamble>
  <p>this is in the preamble</p>
</preamble>'
      to_xml(node.body).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>this is in the body</p>
    </content>
  </hcontainer>
</body>'
    end
  end

  #-------------------------------------------------------------------------------
  # Preamble

  context 'preamble' do
    it 'should support an optional preamble' do
      node = parse :act, <<EOS
PREAMBLE
foo
1. Section
(1) hello
EOS

      node.preamble.text_value.should == "PREAMBLE\nfoo\n"
      to_xml(node.preamble).should == '<preamble>
  <p>foo</p>
</preamble>'
    end

    it 'should support remarks in the preamble' do
      node = parse :act, <<EOS
PREAMBLE

[[remark]]

foo

[[ another remark]]

1. Section
(1) hello
EOS

      to_xml(node.preamble).should == '<preamble>
  <p>
    <remark status="editorial">[remark]</remark>
  </p>
  <p>foo</p>
  <p>
    <remark status="editorial">[ another remark]</remark>
  </p>
</preamble>'
    end

    it 'should support no preamble' do
      node = parse :act, <<EOS
1. Section
bar
EOS

      node.elements.first.text_value.should == ""
    end

    it 'should ignore escaped preamble' do
      node = parse :act, <<EOS
PREFACE

this is the preface

PREAMBLE

\\PREAMBLE

1. Section
(1) hello
EOS

      to_xml(node.preamble).should == '<preamble>
  <p>PREAMBLE</p>
</preamble>'
    end

    it 'should handle weird preamble indicators' do
      node = parse :act, <<EOS
BODY

PREAMBLE

this is actually in the body
EOS

      to_xml(node.body).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>PREAMBLE</p>
      <p>this is actually in the body</p>
    </content>
  </hcontainer>
</body>'
    end

    it 'should handle weird preface indicators' do
      node = parse :act, <<EOS
PREFACE

BODY

PREFACE

this is actually in the body
EOS

      to_xml(node.body).should == '<body>
  <hcontainer eId="hcontainer_1" name="hcontainer">
    <content>
      <p>PREFACE</p>
      <p>this is actually in the body</p>
    </content>
  </hcontainer>
</body>'
    end
  end

  #-------------------------------------------------------------------------------
  # Sections

  context 'section' do
    it 'should handle section numbers after title' do
      subject.parser.options = {section_number_after_title: true}
      node = parse :section, <<EOS
Section
1. (1) hello
EOS

      s = to_xml(node)
      s.should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection eId="sec_1__subsec_1">
    <num>(1)</num>
    <content>
      <p>hello</p>
    </content>
  </subsection>
</section>'
    end

    it 'should handle section numbers before title' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :section, <<EOS
1. Section
(1) hello
EOS
      s = to_xml(node)
      s.should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection eId="sec_1__subsec_1">
    <num>(1)</num>
    <content>
      <p>hello</p>
    </content>
  </subsection>
</section>'
    end

    it 'should handle section numbers without a dot' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :body, <<EOS
1 A section
(1) hello
2 Another section
(2) Another line
EOS
      s = to_xml(node)
      s.should == '<body>
  <section eId="sec_1">
    <num>1.</num>
    <heading>A section</heading>
    <subsection eId="sec_1__subsec_1">
      <num>(1)</num>
      <content>
        <p>hello</p>
      </content>
    </subsection>
  </section>
  <section eId="sec_2">
    <num>2.</num>
    <heading>Another section</heading>
    <subsection eId="sec_2__subsec_2">
      <num>(2)</num>
      <content>
        <p>Another line</p>
      </content>
    </subsection>
  </section>
</body>'
    end

    it 'should handle sections without titles and with subsections' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :section, <<EOS
10. (1) Transporters must remove medical waste.
(2) Without limiting generality, stuff.
EOS
      s = to_xml(node)
      s.should == '<section eId="sec_10">
  <num>10.</num>
  <heading/>
  <subsection eId="sec_10__subsec_1">
    <num>(1)</num>
    <content>
      <p>Transporters must remove medical waste.</p>
    </content>
  </subsection>
  <subsection eId="sec_10__subsec_2">
    <num>(2)</num>
    <content>
      <p>Without limiting generality, stuff.</p>
    </content>
  </subsection>
</section>'
    end

    it 'should handle sections that dive straight into lists' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :section, <<EOS
1. Section
(a) first
(b) second
and some stuff
EOS
      
      s = to_xml(node)
      s.should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <blockList eId="sec_1__hcontainer_1__list_1" renest="true">
        <item eId="sec_1__hcontainer_1__list_1__item_a">
          <num>(a)</num>
          <p>first</p>
        </item>
        <item eId="sec_1__hcontainer_1__list_1__item_b">
          <num>(b)</num>
          <p>second</p>
        </item>
      </blockList>
      <p>and some stuff</p>
    </content>
  </hcontainer>
</section>'
    end

    it 'should handle sections with inline markup in headings' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :section, <<EOS
1. Section **bold** [foo](/za/act/1990/1)

something
EOS
      
      s = to_xml(node)
      s.should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section <b>bold</b> <ref href="/za/act/1990/1">foo</ref></heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <p>something</p>
    </content>
  </hcontainer>
</section>'
    end

    it 'should handle prefixed sections with inline markup in headings' do
      subject.parser.options = {section_number_after_title: true}
      node = parse :section, <<EOS
  Section **bold** [foo](/za/act/1990/1)
1.

something
EOS
      
      s = to_xml(node)
      s.should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section <b>bold</b> <ref href="/za/act/1990/1">foo</ref></heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <p>something</p>
    </content>
  </hcontainer>
</section>'
    end

    it 'should handle a naked statement' do
      should_parse :section, <<EOS
1. Section

naked statement
EOS
    end

    it 'should handle a naked statement and blocklist' do
      node = parse :section, <<EOS
1. Section
naked statement (c) blah
(a) foo
(b) bar
EOS
      to_xml(node, "").should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <p>naked statement (c) blah</p>
      <blockList eId="sec_1__hcontainer_1__list_1" renest="true">
        <item eId="sec_1__hcontainer_1__list_1__item_a">
          <num>(a)</num>
          <p>foo</p>
        </item>
        <item eId="sec_1__hcontainer_1__list_1__item_b">
          <num>(b)</num>
          <p>bar</p>
        </item>
      </blockList>
    </content>
  </hcontainer>
</section>'
    end

    it 'should handle empty subsections and empty lines' do
      node = parse :section, <<EOS
1. Section

(1)

something

(2) Schedule 1

(a) Part 1

(b) thing
EOS
      to_xml(node, "").should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection eId="sec_1__subsec_1">
    <num>(1)</num>
    <content>
      <p>something</p>
    </content>
  </subsection>
  <subsection eId="sec_1__subsec_2">
    <num>(2)</num>
    <content>
      <p>Schedule 1</p>
      <blockList eId="sec_1__subsec_2__list_1" renest="true">
        <item eId="sec_1__subsec_2__list_1__item_a">
          <num>(a)</num>
          <p>Part 1</p>
        </item>
        <item eId="sec_1__subsec_2__list_1__item_b">
          <num>(b)</num>
          <p>thing</p>
        </item>
      </blockList>
    </content>
  </subsection>
</section>'
    end

    it 'should ignore escaped section headings' do
      node = parse :section, <<EOS
1. Section

\\1. ignored
\\2. another line
stuff
\\3. a third
EOS
      to_xml(node, "").should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <p>1. ignored</p>
      <p>2. another line</p>
      <p>stuff</p>
      <p>3. a third</p>
    </content>
  </hcontainer>
</section>'
    end

    it 'should handle escaped empty lines' do
      node = parse :section, <<EOS
1. Section

\\

stuff
EOS
      to_xml(node, "").should == '<section eId="sec_1">
  <num>1.</num>
  <heading>Section</heading>
  <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
    <content>
      <p>stuff</p>
    </content>
  </hcontainer>
</section>'
    end

    it 'should not clash with dotted subsections' do
      node = parse :section, <<EOS
3. Types of informal trading
3.1
Informal trading may include, amongst others:-
3.1.1 street trading;
3.1.2 trading in pedestrian malls;
EOS
      to_xml(node, '').should == '<section eId="sec_3">
  <num>3.</num>
  <heading>Types of informal trading</heading>
  <subsection eId="sec_3__subsec_3-1">
    <num>3.1</num>
    <content>
      <p>Informal trading may include, amongst others:-</p>
      <blockList eId="sec_3__subsec_3-1__list_1" renest="true">
        <item eId="sec_3__subsec_3-1__list_1__item_3-1-1">
          <num>3.1.1</num>
          <p>street trading;</p>
        </item>
        <item eId="sec_3__subsec_3-1__list_1__item_3-1-2">
          <num>3.1.2</num>
          <p>trading in pedestrian malls;</p>
        </item>
      </blockList>
    </content>
  </subsection>
</section>'
    end
  end

  #-------------------------------------------------------------------------------
  # crossheadings

  context 'crossheadings' do
    it 'should handle a inline_items in crossheadings' do
      node = parse :crossheading, "CROSSHEADING something [[remark]] [link](/foo/bar)\n"
      to_xml(node, '').should == '<hcontainer eId="hcontainer_1" name="crossheading">
  <heading>something <remark status="editorial">[remark]</remark> <ref href="/foo/bar">link</ref></heading>
</hcontainer>'
    end

    it 'should not be allowed in preface' do
      node = parse :act, '
PREFACE
      
Some text

CROSSHEADING In the body

1. Section 1
      
Text
'
      today = Time.now.strftime('%Y-%m-%d')
      to_xml(node, "").should == '<act contains="originalVersion" name="act">
  <meta>
    <identification source="#slaw">
      <FRBRWork>
        <FRBRthis value="/za/act/1980/01/main"/>
        <FRBRuri value="/za/act/1980/01"/>
        <FRBRalias value="Short Title" name="title"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRcountry value="za"/>
      </FRBRWork>
      <FRBRExpression>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRlanguage language="eng"/>
      </FRBRExpression>
      <FRBRManifestation>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="' + today + '" name="Generation"/>
        <FRBRauthor href="#slaw"/>
      </FRBRManifestation>
    </identification>
    <references source="#this">
      <TLCOrganization eId="slaw" href="https://github.com/longhotsummer/slaw" showAs="Slaw"/>
      <TLCOrganization eId="council" href="/ontology/organization/za/council" showAs="Council"/>
    </references>
  </meta>
  <preface>
    <p>Some text</p>
  </preface>
  <body>
    <hcontainer eId="hcontainer_1" name="crossheading">
      <heading>In the body</heading>
    </hcontainer>
    <section eId="sec_1">
      <num>1.</num>
      <heading>Section 1</heading>
      <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
        <content>
          <p>Text</p>
        </content>
      </hcontainer>
    </section>
  </body>
</act>'
    end

    it 'should not be allowed in preamble' do
      node = parse :act, '
PREAMBLE
      
Some text

CROSSHEADING In the body

1. Section 1
      
Text
'
      today = Time.now.strftime('%Y-%m-%d')
      to_xml(node, "").should == '<act contains="originalVersion" name="act">
  <meta>
    <identification source="#slaw">
      <FRBRWork>
        <FRBRthis value="/za/act/1980/01/main"/>
        <FRBRuri value="/za/act/1980/01"/>
        <FRBRalias value="Short Title" name="title"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRcountry value="za"/>
      </FRBRWork>
      <FRBRExpression>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="1980-01-01" name="Generation"/>
        <FRBRauthor href="#council"/>
        <FRBRlanguage language="eng"/>
      </FRBRExpression>
      <FRBRManifestation>
        <FRBRthis value="/za/act/1980/01/eng@/main"/>
        <FRBRuri value="/za/act/1980/01/eng@"/>
        <FRBRdate date="' + today + '" name="Generation"/>
        <FRBRauthor href="#slaw"/>
      </FRBRManifestation>
    </identification>
    <references source="#this">
      <TLCOrganization eId="slaw" href="https://github.com/longhotsummer/slaw" showAs="Slaw"/>
      <TLCOrganization eId="council" href="/ontology/organization/za/council" showAs="Council"/>
    </references>
  </meta>
  <preamble>
    <p>Some text</p>
  </preamble>
  <body>
    <hcontainer eId="hcontainer_1" name="crossheading">
      <heading>In the body</heading>
    </hcontainer>
    <section eId="sec_1">
      <num>1.</num>
      <heading>Section 1</heading>
      <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
        <content>
          <p>Text</p>
        </content>
      </hcontainer>
    </section>
  </body>
</act>'
    end
  end

  #-------------------------------------------------------------------------------
  # longTitle

  context 'longtitle' do
    it 'should handle a basic longtitle' do
      node = parse :longtitle, "LONGTITLE something [[remark]] [link](/foo/bar)\n"
      to_xml(node, '').should == '<longTitle>
  <p>something <remark status="editorial">[remark]</remark> <ref href="/foo/bar">link</ref></p>
</longTitle>'
    end

    it 'should handle a longtitle in a preface' do
      node = parse :act, <<EOS
PREFACE

Blah blah

LONGTITLE a long title

\\LONGTITLE escaped

Enacting clause

1. Section
(1) hello
EOS

      to_xml(node.preface).should == '<preface>
  <p>Blah blah</p>
  <longTitle>
    <p>a long title</p>
  </longTitle>
  <p>LONGTITLE escaped</p>
  <p>Enacting clause</p>
</preface>'
    end

    it 'should ignore a longtitle in preamble' do
      node = parse :preamble, <<EOS
PREAMBLE

LONGTITLE a long title
EOS

      to_xml(node).should == '<preamble>
  <p>LONGTITLE a long title</p>
</preamble>'
    end

    it 'should ignore a longtitle in body' do
      node = parse :body, <<EOS
1. Section

LONGTITLE a long title
EOS

      to_xml(node).should == '<body>
  <section eId="sec_1">
    <num>1.</num>
    <heading>Section</heading>
    <hcontainer eId="sec_1__hcontainer_1" name="hcontainer">
      <content>
        <p>LONGTITLE a long title</p>
      </content>
    </hcontainer>
  </section>
</body>'
    end
  end
end
