# encoding: UTF-8

require 'slaw'

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

  #-------------------------------------------------------------------------------
  # General body

  describe 'body' do
    it 'should handle general content before sections' do
      node = parse :body, <<EOS
Some content before the section

1. Section
Hello there
EOS
      to_xml(node).should == '<body>
  <paragraph id="paragraph-0">
    <content>
      <p>Some content before the section</p>
    </content>
  </paragraph>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</body>'
    end

    it 'should handle blocklists before sections' do
      node = parse :body, <<EOS
Some content before the section

(a) foo
(b) bar

1. Section
Hello there
EOS
      to_xml(node).should == '<body>
  <paragraph id="paragraph-0">
    <content>
      <p>Some content before the section</p>
      <blockList id="paragraph-0.list1">
        <item id="paragraph-0.list1.a">
          <num>(a)</num>
          <p>foo</p>
        </item>
        <item id="paragraph-0.list1.b">
          <num>(b)</num>
          <p>bar</p>
        </item>
      </blockList>
    </content>
  </paragraph>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</body>'
    end

    it 'should handle escaped content' do
      node = parse :body, <<EOS
\\1. ignored

1. Section
\\Chapter 2 ignored
EOS
      to_xml(node).should == '<body>
  <paragraph id="paragraph-0">
    <content>
      <p>1. ignored</p>
    </content>
  </paragraph>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Chapter 2 ignored</p>
      </content>
    </paragraph>
  </section>
</body>'
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
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</chapter>'
    end

    it 'should handle chapters without titles' do
      node = parse :chapter, <<EOS
ChaPTEr 2:

1. Section
Hello there
EOS
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</chapter>'
    end

    it 'should handle general content at the start of a chapter' do
      node = parse :chapter, <<EOS
Chapter 2
The Chapter Heading

Some lines at the start of the chapter.
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Chapter Heading'
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <paragraph id="chapter-2.paragraph-0">
    <content>
      <p>Some lines at the start of the chapter.</p>
    </content>
  </paragraph>
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
      node.heading.title.should == 'The Chapter Heading'
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <paragraph id="chapter-2.paragraph-0">
    <content>
      <p>Some lines at the start of the chapter.</p>
    </content>
  </paragraph>
  <section id="section-1">
    <num>1.</num>
    <heading>Section 1</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Section text.</p>
      </content>
    </paragraph>
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
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <heading>The Chapter Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</chapter>'
    end

    it 'should handle empty chapters' do
      node = parse :body, <<EOS
Chapter 2 The Chapter Heading
Chapter 3 The Other Heading
EOS
      to_xml(node).should == '<body>
  <chapter id="chapter-2">
    <num>2</num>
    <heading>The Chapter Heading</heading>
  </chapter>
  <chapter id="chapter-3">
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
      to_xml(node).should == '<chapter id="chapter-2">
  <num>2</num>
  <heading>The Chapter</heading>
  <paragraph id="chapter-2.paragraph-0">
    <content>
      <table id="chapter-2.paragraph-0.table0">
        <tr>
          <td>
            <p>foo</p>
          </td>
        </tr>
      </table>
    </content>
  </paragraph>
</chapter>'
    end

    it 'should ignore escaped chapter headers' do
      node = parse :chapter, <<EOS
Chapter 1 The Chapter

Stuff

\\Chapter 2 - Ignored

More stuff
EOS
      to_xml(node).should == '<chapter id="chapter-1">
  <num>1</num>
  <heading>The Chapter</heading>
  <paragraph id="chapter-1.paragraph-0">
    <content>
      <p>Stuff</p>
      <p>Chapter 2 - Ignored</p>
      <p>More stuff</p>
    </content>
  </paragraph>
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
1. Section
Hello there
EOS
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</part>'
    end

    it 'should handle part headers with dashes' do
      node = parse :part, <<EOS
Part 2 - The Part Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</part>'
    end

    it 'should handle part headers with colons' do
      node = parse :part, <<EOS
Part 2: The Part Heading
1. Section
Hello there
EOS
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</part>'
    end

    it 'should handle part headers without titles' do
      node = parse :part, <<EOS
Part 2:

1. Section
Hello there
EOS
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
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
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
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
      to_xml(node).should == '<part id="part-1">
  <num>1</num>
  <heading>PREVENTION AND SUPPRESSION OF HEALTH NUISANCES</heading>
  <section id="section-1">
    <num>1.</num>
    <heading/>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>No owner or occupier of any shop or business premises or vacant land adjoining a shop or business premises shall cause a health nuisance.</p>
      </content>
    </paragraph>
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
      node.heading.title.should == 'The Part Heading'
      to_xml(node).should == '<part id="part-2">
  <num>2</num>
  <heading>The Part Heading</heading>
  <paragraph id="part-2.paragraph-0">
    <content>
      <p>Some text before the part.</p>
    </content>
  </paragraph>
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <paragraph id="section-1.paragraph-0">
      <content>
        <p>Hello there</p>
      </content>
    </paragraph>
  </section>
</part>'
    end

    it 'should handle empty parts' do
      node = parse :body, <<EOS
Part 2 The Part Heading
Part 3 The Other Heading
EOS
      to_xml(node).should == '<body>
  <part id="part-2">
    <num>2</num>
    <heading>The Part Heading</heading>
  </part>
  <part id="part-3">
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
  <part id="part-2">
    <num>2</num>
    <heading>The Part Heading</heading>
    <paragraph id="part-2.paragraph-0">
      <content>
        <p>Part 3 ignored</p>
      </content>
    </paragraph>
  </part>
</body>'
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
      to_xml(node, "", 1).should == '<subsection id="2">
  <num>(2)</num>
  <content>
    <p>title</p>
    <blockList id="2.list1">
      <item id="2.list1.a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item id="2.list1.b">
        <num>(b)</num>
        <p>two</p>
      </item>
      <item id="2.list1.c">
        <num>(c)</num>
        <p>three</p>
      </item>
      <item id="2.list1.i">
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
      to_xml(node, "", 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <blockList id="1.list0">
      <item id="1.list0.a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item id="1.list0.b">
        <num>(b)</num>
        <p>two</p>
      </item>
      <item id="1.list0.c">
        <num>(c)</num>
        <p>three</p>
      </item>
      <item id="1.list0.i">
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
      to_xml(node, "", 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <blockList id="1.list0">
      <item id="1.list0.a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item id="1.list0.b">
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
      to_xml(node).should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection id="section-1.1">
    <num>(1)</num>
    <content>
      <p/>
    </content>
  </subsection>
  <subsection id="section-1.2">
    <num>(2)</num>
    <content>
      <p>next line</p>
    </content>
  </subsection>
  <subsection id="section-1.3">
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
      to_xml(node, "", 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <p>here\'s my really cool list,</p>
    <blockList id="1.list1">
      <item id="1.list1.a">
        <num>(a)</num>
        <p>one</p>
      </item>
      <item id="1.list1.b">
        <num>(b)</num>
        <p/>
      </item>
      <item id="1.list1.i">
        <num>(i)</num>
        <p>single</p>
      </item>
      <item id="1.list1.ii">
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
      to_xml(node, "", 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <p>here\'s my really cool list,</p>
    <blockList id="1.list1">
      <item id="1.list1.a">
        <num>(a)</num>
        <p/>
      </item>
      <item id="1.list1.b">
        <num>(b)</num>
        <p/>
      </item>
      <item id="1.list1.i">
        <num>(i)</num>
        <p>single</p>
      </item>
      <item id="1.list1.ii">
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
      end

      it 'should handle dotted number sublists' do
        node = parse(:subsection, <<EOS
          9.9 foo
          9.9.1 item1
          9.9.2 item2
          9.9.2.1 item3
EOS
                    )
        to_xml(node, '', 1).should == '<subsection id="9.9">
  <num>9.9</num>
  <content>
    <p>foo</p>
    <blockList id="9.9.list1">
      <item id="9.9.list1.9.9.1">
        <num>9.9.1</num>
        <p>item1</p>
      </item>
      <item id="9.9.list1.9.9.2">
        <num>9.9.2</num>
        <p>item2</p>
      </item>
      <item id="9.9.list1.9.9.2.1">
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

      to_xml(node, '', 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <p>a list</p>
    <blockList id="1.list1">
      <item id="1.list1.a">
        <num>(a)</num>
        <p>item 1</p>
      </item>
      <item id="1.list1.b">
        <num>(b)</num>
        <p>item 2</p>
      </item>
    </blockList>
    <p>some text</p>
    <blockList id="1.list3">
      <item id="1.list3.c">
        <num>(c)</num>
        <p>item 3</p>
      </item>
      <item id="1.list3.d">
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

      to_xml(node, '', 1).should == '<subsection id="1">
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
  <section id="section-1">
    <num>1.</num>
    <heading>Section</heading>
    <subsection id="section-1.2">
      <num>(2)</num>
      <content>
        <p>Schedule 1 is cool.</p>
      </content>
    </subsection>
    <subsection id="section-1.3">
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
      to_xml(node, "").should == '<act contains="originalVersion">
  <meta>
    <identification source="#slaw">
      <FRBRWork>
        <FRBRthis value="/za/act/1980/01/main"/>
        <FRBRuri value="/za/act/1980/01"/>
        <FRBRalias value="Short Title"/>
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
      <TLCOrganization id="slaw" href="https://github.com/longhotsummer/slaw" showAs="Slaw"/>
      <TLCOrganization id="council" href="/ontology/organization/za/council" showAs="Council"/>
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
    <section id="section-1">
      <num>1.</num>
      <heading>Section</heading>
      <subsection id="section-1.1">
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

    it 'should support prefaces and preambles' do
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
      s.should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection id="section-1.1">
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
      s.should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection id="section-1.1">
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
  <section id="section-1">
    <num>1.</num>
    <heading>A section</heading>
    <subsection id="section-1.1">
      <num>(1)</num>
      <content>
        <p>hello</p>
      </content>
    </subsection>
  </section>
  <section id="section-2">
    <num>2.</num>
    <heading>Another section</heading>
    <subsection id="section-2.2">
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
      s.should == '<section id="section-10">
  <num>10.</num>
  <heading/>
  <subsection id="section-10.1">
    <num>(1)</num>
    <content>
      <p>Transporters must remove medical waste.</p>
    </content>
  </subsection>
  <subsection id="section-10.2">
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
      s.should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <paragraph id="section-1.paragraph-0">
    <content>
      <blockList id="section-1.paragraph-0.list0">
        <item id="section-1.paragraph-0.list0.a">
          <num>(a)</num>
          <p>first</p>
        </item>
        <item id="section-1.paragraph-0.list0.b">
          <num>(b)</num>
          <p>second</p>
        </item>
      </blockList>
      <p>and some stuff</p>
    </content>
  </paragraph>
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
      to_xml(node, "").should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <paragraph id="section-1.paragraph-0">
    <content>
      <p>naked statement (c) blah</p>
      <blockList id="section-1.paragraph-0.list1">
        <item id="section-1.paragraph-0.list1.a">
          <num>(a)</num>
          <p>foo</p>
        </item>
        <item id="section-1.paragraph-0.list1.b">
          <num>(b)</num>
          <p>bar</p>
        </item>
      </blockList>
    </content>
  </paragraph>
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
      to_xml(node, "").should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <subsection id="section-1.1">
    <num>(1)</num>
    <content>
      <p>something</p>
    </content>
  </subsection>
  <subsection id="section-1.2">
    <num>(2)</num>
    <content>
      <p>Schedule 1</p>
      <blockList id="section-1.2.list1">
        <item id="section-1.2.list1.a">
          <num>(a)</num>
          <p>Part 1</p>
        </item>
        <item id="section-1.2.list1.b">
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
      to_xml(node, "").should == '<section id="section-1">
  <num>1.</num>
  <heading>Section</heading>
  <paragraph id="section-1.paragraph-0">
    <content>
      <p>1. ignored</p>
      <p>2. another line</p>
      <p>stuff</p>
      <p>3. a third</p>
    </content>
  </paragraph>
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
      to_xml(node, '').should == '<section id="section-3">
  <num>3.</num>
  <heading>Types of informal trading</heading>
  <subsection id="section-3.3.1">
    <num>3.1</num>
    <content>
      <p>Informal trading may include, amongst others:-</p>
      <blockList id="section-3.3.1.list1">
        <item id="section-3.3.1.list1.3.1.1">
          <num>3.1.1</num>
          <p>street trading;</p>
        </item>
        <item id="section-3.3.1.list1.3.1.2">
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
  # schedules

  context 'schedules' do
    it 'should handle a simple schedule' do
      node = parse :schedules, <<EOS
Schedule

Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-schedule">
  <doc name="schedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule">
        <paragraph id="schedule.paragraph-0">
          <content>
            <p>Subject to approval in terms of this By-Law, the erection:</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
        <section id="section-2">
          <num>2.</num>
          <heading>Bar</heading>
        </section>
      </article>
    </mainBody>
  </doc>
</component>'
    end

    it 'should serialise many schedules correctly' do
      node = parse :schedules_container, <<EOS
Schedule "2"
A Title
1. Foo
2. Bar
Schedule 3
Another Title
Baz
Boom
EOS

      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == <<EOS
<components>
  <component id="component-schedule2">
    <doc name="schedule2">
      <meta>
        <identification source="#slaw">
          <FRBRWork>
            <FRBRthis value="/za/act/1980/01/schedule2"/>
            <FRBRuri value="/za/act/1980/01"/>
            <FRBRalias value="Schedule 2"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council"/>
            <FRBRcountry value="za"/>
          </FRBRWork>
          <FRBRExpression>
            <FRBRthis value="/za/act/1980/01/eng@/schedule2"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council"/>
            <FRBRlanguage language="eng"/>
          </FRBRExpression>
          <FRBRManifestation>
            <FRBRthis value="/za/act/1980/01/eng@/schedule2"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="#{today}" name="Generation"/>
            <FRBRauthor href="#slaw"/>
          </FRBRManifestation>
        </identification>
      </meta>
      <mainBody>
        <article id="schedule2">
          <heading>A Title</heading>
          <section id="section-1">
            <num>1.</num>
            <heading>Foo</heading>
          </section>
          <section id="section-2">
            <num>2.</num>
            <heading>Bar</heading>
          </section>
        </article>
      </mainBody>
    </doc>
  </component>
  <component id="component-schedule3">
    <doc name="schedule3">
      <meta>
        <identification source="#slaw">
          <FRBRWork>
            <FRBRthis value="/za/act/1980/01/schedule3"/>
            <FRBRuri value="/za/act/1980/01"/>
            <FRBRalias value="Schedule 3"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council"/>
            <FRBRcountry value="za"/>
          </FRBRWork>
          <FRBRExpression>
            <FRBRthis value="/za/act/1980/01/eng@/schedule3"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council"/>
            <FRBRlanguage language="eng"/>
          </FRBRExpression>
          <FRBRManifestation>
            <FRBRthis value="/za/act/1980/01/eng@/schedule3"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="#{today}" name="Generation"/>
            <FRBRauthor href="#slaw"/>
          </FRBRManifestation>
        </identification>
      </meta>
      <mainBody>
        <article id="schedule3">
          <heading>Another Title</heading>
          <paragraph id="schedule3.paragraph-0">
            <content>
              <p>Baz</p>
              <p>Boom</p>
            </content>
          </paragraph>
        </article>
      </mainBody>
    </doc>
  </component>
</components>
EOS
    .strip

    end

    it 'should handle a schedule with a title and a number' do
      node = parse :schedules, <<EOS
Schedule 1 - First Schedule
Schedule Heading

Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-schedule1">
  <doc name="schedule1">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule1"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule1">
        <heading>Schedule Heading</heading>
        <paragraph id="schedule1.paragraph-0">
          <content>
            <p>Subject to approval in terms of this By-Law, the erection:</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
        <section id="section-2">
          <num>2.</num>
          <heading>Bar</heading>
        </section>
      </article>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule with dot in the number' do
      node = parse :schedules, <<EOS
Schedule 1. First Schedule
Schedule Heading

Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-schedule1">
  <doc name="schedule1">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule1"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule1">
        <heading>Schedule Heading</heading>
        <paragraph id="schedule1.paragraph-0">
          <content>
            <p>Subject to approval in terms of this By-Law, the erection:</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
        <section id="section-2">
          <num>2.</num>
          <heading>Bar</heading>
        </section>
      </article>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule with a title' do
      node = parse :schedules, <<EOS
Schedule - First Schedule

Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-firstschedule">
  <doc name="firstschedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/firstschedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="firstschedule">
        <paragraph id="firstschedule.paragraph-0">
          <content>
            <p>Subject to approval in terms of this By-Law, the erection:</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
        <section id="section-2">
          <num>2.</num>
          <heading>Bar</heading>
        </section>
      </article>
    </mainBody>
  </doc>
</component>'
    end

    it 'should serialise a single schedule without a heading' do
      node = parse :schedules, <<EOS
Schedule "1"

Other than as is set out hereinbelow, no signs other than locality bound signs, temporary signs including loose portable sign, estate agents signs, newspaper headline posters and posters (the erection of which must comply with the appropriate schedules pertinent thereto) shall be erected on Municipal owned land.
1. Foo
2. Bar
EOS

      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == <<EOS
<component id="component-schedule1">
  <doc name="schedule1">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule1"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="Schedule 1"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="#{today}" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule1">
        <paragraph id="schedule1.paragraph-0">
          <content>
            <p>Other than as is set out hereinbelow, no signs other than locality bound signs, temporary signs including loose portable sign, estate agents signs, newspaper headline posters and posters (the erection of which must comply with the appropriate schedules pertinent thereto) shall be erected on Municipal owned land.</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
        <section id="section-2">
          <num>2.</num>
          <heading>Bar</heading>
        </section>
      </article>
    </mainBody>
  </doc>
</component>
EOS
      .strip
    end

    it 'should support rich parts, chapters and sections in a schedule' do
      node = parse :schedules, <<EOS
Schedule 1
Forms

Part I
Form of authentication statement

This printed impression has been carefully compared by me with the bill which was passed by Parliament and found by me to be a true copy of the bill.

Part II
Form of statement of the President’s assent.

I signify my assent to the bill and a whole bunch of other stuff.
EOS

      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == <<EOS
<component id="component-schedule1">
  <doc name="schedule1">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule1"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="Schedule 1"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="#{today}" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule1">
        <heading>Forms</heading>
        <part id="part-I">
          <num>I</num>
          <heading>Form of authentication statement</heading>
          <paragraph id="part-I.paragraph-0">
            <content>
              <p>This printed impression has been carefully compared by me with the bill which was passed by Parliament and found by me to be a true copy of the bill.</p>
            </content>
          </paragraph>
        </part>
        <part id="part-II">
          <num>II</num>
          <heading>Form of statement of the President’s assent.</heading>
          <paragraph id="part-II.paragraph-0">
            <content>
              <p>I signify my assent to the bill and a whole bunch of other stuff.</p>
            </content>
          </paragraph>
        </part>
      </article>
    </mainBody>
  </doc>
</component>
EOS
      .strip
    end

    it 'should not get confused by schedule headings in TOC' do
      parse :schedules_container, <<EOS
Schedule 1. Summoning and procedure of Joint Sittings of Senate and House of Assembly.
Schedule 2. Oaths.
Schedule 3. Matters which shall continue to be regulated by Swazi Law and Custom.
Schedule 4. Specially entrenched provisions and entrenched provisions.
EOS
    end

    it 'should handle escaped schedules' do
      node = parse :schedules, <<EOS
Schedule

Subject to approval in terms of this By-Law.

\\Schedule another

More stuff
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-schedule">
  <doc name="schedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/schedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/schedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/schedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule">
        <paragraph id="schedule.paragraph-0">
          <content>
            <p>Subject to approval in terms of this By-Law.</p>
            <p>Schedule another</p>
            <p>More stuff</p>
          </content>
        </paragraph>
      </article>
    </mainBody>
  </doc>
</component>'
    end

  end

  #-------------------------------------------------------------------------------
  # clauses

  context 'clauses' do
    it 'should handle a simple clause' do
      node = parse :clauses, "simple text"
      node.text_value.should == "simple text"
    end

    it 'should handle a clause with a remark' do
      node = parse :clauses, "simple [[remark]]. text"
      node.text_value.should == "simple [[remark]]. text"
      node.elements[7].is_a?(Slaw::Grammars::ZA::Act::Remark).should be_true

      node = parse :clauses, "simple [[remark]][[another]] text"
      node.text_value.should == "simple [[remark]][[another]] text"
      node.elements[7].is_a?(Slaw::Grammars::ZA::Act::Remark).should be_true
      node.elements[7].is_a?(Slaw::Grammars::ZA::Act::Remark).should be_true
    end
  end
end
