# encoding: UTF-8

require 'builder'

require 'slaw'

describe Slaw::ActGenerator do
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

  def to_xml(node, indent=nil, *args)
    s = ""
    b = Builder::XmlMarkup.new(target: s, indent: indent)
    node.to_xml(b, *args)
    s
  end

  #-------------------------------------------------------------------------------
  # Chapters
  #
  describe 'chapters' do
    it 'should handle chapter headers' do
      node = parse :chapter, <<EOS
ChaPTEr 2
The Chapter Heading
1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Chapter Heading'
      to_xml(node).should == "<chapter id=\"chapter-2\"><num>2</num><heading>The Chapter Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></chapter>"
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
      node.num.should == "2"
      node.heading.title.should == 'The Part Heading'
      to_xml(node).should == "<part id=\"part-2\"><num>2</num><heading>The Part Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></part>"
    end

    it 'should handle part headers with dashes' do
      node = parse :part, <<EOS
Part 2 - The Part Heading
1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Part Heading'
      to_xml(node).should == "<part id=\"part-2\"><num>2</num><heading>The Part Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></part>"
    end

    it 'should handle part headers with colons' do
      node = parse :part, <<EOS
Part 2: The Part Heading
1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Part Heading'
      to_xml(node).should == "<part id=\"part-2\"><num>2</num><heading>The Part Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></part>"
    end

    it 'should handle parts and odd section numbers' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
PART 1
PREVENTION AND SUPPRESSION OF HEALTH NUISANCES
1.
No owner or occupier of any shop or business premises or vacant land adjoining a shop or business premises shall cause a health nuisance.
EOS

      part = node.elements[1].elements[0].elements[1].elements[0]
      part.heading.num.should == "1"
      part.heading.title.should == "PREVENTION AND SUPPRESSION OF HEALTH NUISANCES"

      section = part.elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.section_title_prefix.number_letter.text_value.should == "1"
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

    it 'should handle a naked statement' do
      should_parse :subsection, 'naked statement'
    end

    it 'should handle a naked statement and blocklist' do
      node = parse :subsection, <<EOS
        naked statement (c) blah
        (a) foo
        (b) bar
EOS
      node.statement.content.text_value.should == "naked statement (c) blah"
      node.blocklist.elements.first.num.should == "(a)"
    end

    it 'should handle a blocklist' do
      node = parse :subsection, <<EOS
        (2) title
        (a) one
        (b) two
        (c) three
        (i) four
EOS
      node.statement.num.should == "(2)"
      node.statement.content.text_value.should == "title"
    end

    it 'should handle a subsection that dives straight into a list' do
      node = parse(:subsection, <<EOS
        (1) (a) one
        (b) two
        (c) three
        (i) four
EOS
                  )
      node.statement.content.should be_nil
      node.blocklist.elements.first.num.should == "(a)"
      node.blocklist.elements.first.content.should == "one"
    end

    it 'should handle a blocklist that dives straight into another list' do
      node = parse(:subsection, <<EOS
        (1) here's my really cool list,
        (a) one
        (b) (i) single
        (ii) double
EOS
                  )
      node.statement.content.text_value.should == "here's my really cool list,"
      node.blocklist.elements.first.num.should == "(a)"
      node.blocklist.elements.first.content.should == "one"
      node.blocklist.elements[1].num.should == "(b)"
      node.blocklist.elements[1].content.should be_nil
      node.blocklist.elements[2].num.should == "(i)"
      node.blocklist.elements[2].content.should == "single"
    end

    context 'dotted numbers' do
      it 'should handle dotted number subsection numbers' do
        node = parse :subsection, <<EOS
          9.9. foo
EOS
        node.statement.content.text_value.should == "foo"
        node.statement.num.should == "9.9"
      end

      it 'should handle dotted number sublists' do
        node = parse(:subsection, <<EOS
          9.9 foo
          9.9.1 item1
          9.9.2 item2
          9.9.2.1 item3
EOS
                    )
        node.statement.content.text_value.should == "foo"
        node.blocklist.elements.first.num.should == "9.9.1"
        node.blocklist.elements.first.content.should == "item1"

        node.blocklist.elements[2].num.should == "9.9.2.1"
        node.blocklist.elements[2].content.should == "item3"
      end
    end
  end

  #-------------------------------------------------------------------------------
  # Remarks

  describe 'remark' do
    it 'should handle basic remarks' do
      should_parse :remark, <<EOS
      [Section 2 amended by Act 23 of 2004]
EOS
    end

    it 'should handle a remark' do
      node = parse :remark, <<EOS
      [Section 2 amended by Act 23 of 2004]
EOS
      node.content.text_value.should == "Section 2 amended by Act 23 of 2004"
    end

    it 'should handle a remark in a section' do
      node = parse :section, <<EOS
      1. Section title
      Some text is a long line.

      [Section 1 amended by Act 23 of 2004]
EOS
      to_xml(node).should == "<section id=\"section-1\"><num>1.</num><heading>Section title</heading><subsection id=\"section-1.subsection-0\"><content><p>Some text is a long line.</p></content></subsection><p><remark>[Section 1 amended by Act 23 of 2004]</remark></p></section>"
    end
  end

  #-------------------------------------------------------------------------------
  # Numbered statements

  describe 'numbered_statement' do
    it 'should handle basic numbered statements' do
      should_parse :numbered_statement, '(1) foo bar'
      should_parse :numbered_statement, '(1a) foo bar'
    end
  end

  #-------------------------------------------------------------------------------
  # Preamble

  context 'preamble' do
    it 'should consider any text at the start to be preamble' do
      node = parse :act, <<EOS
foo
bar
(1) stuff
(2) more stuff
baz
1. Section
(1) hello
EOS

      node.elements.first.text_value.should == "foo
bar
(1) stuff
(2) more stuff
baz
"
    end

    it 'should support an optional preamble' do
      node = parse :act, <<EOS
PREAMBLE
foo
1. Section
(1) hello
EOS

      node.elements.first.text_value.should == "PREAMBLE\nfoo\n"
    end

    it 'should support no preamble' do
      node = parse :act, <<EOS
1. Section
bar
EOS

      node.elements.first.text_value.should == ""
    end
  end


  #-------------------------------------------------------------------------------
  # Sections

  context 'sections' do
    it 'should handle section numbers after title' do
      subject.parser.options = {section_number_after_title: true}
      node = parse :act, <<EOS
Section
1. (1) hello
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.content.text_value.should == "Section"
      section.section_title.section_title_prefix.number_letter.text_value.should == "1"
    end

    it 'should handle section numbers before title' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
1. Section
(1) hello
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "Section"
      section.section_title.num.should == "1"
    end

    it 'should handle section numbers without a dot' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
1 A section
(1) hello
2 Another section
(2) Another line
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "A section"
      section.section_title.num.should == "1"

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[1]
      section.section_title.title.should == "Another section"
      section.section_title.num.should == "2"
    end

    it 'should handle sections without titles' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
1. No owner or occupier of any shop or business premises or vacant land, blah blah
2. Notwithstanding the provision of any other By-law or legislation no person shall—
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "No owner or occupier of any shop or business premises or vacant land, blah blah"
      section.section_title.num.should == "1"

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[1]
      section.section_title.title.should == ""
      section.section_title.num.should == "2"
      section.subsections.elements[0].statement.content.text_value.should == "Notwithstanding the provision of any other By-law or legislation no person shall—"
    end

    it 'should handle sections without titles and with subsections' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
10. (1) Transporters must remove medical waste.
(2) Without limiting generality, stuff.
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.num.should == "10"
      section.subsections.elements[0].statement.num.should == "(1)"
      section.subsections.elements[0].statement.content.text_value.should == "Transporters must remove medical waste."
    end

    it 'should realise complex section titles are actually section content' do
      subject.parser.options = {section_number_after_title: false}
      node = parse :act, <<EOS
10. The owner of any premises which is let or sublet to more than one tenant, shall maintain at all times in a clean and sanitary condition every part of such premises as may be used in common by more than one tenant.
11. No person shall keep, cause or suffer to be kept any factory or trade premises so as to cause or give rise to smells or effluvia that constitute a health nuisance.
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.num.should == "10"
      section.subsections.elements[0].statement.content.text_value.should == "The owner of any premises which is let or sublet to more than one tenant, shall maintain at all times in a clean and sanitary condition every part of such premises as may be used in common by more than one tenant."
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

      sched = node.schedules.elements[0]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.statements.elements[0].content.text_value.should == "Subject to approval in terms of this By-Law, the erection:"
      sched.statements.elements[1].content.text_value.should == "1. Foo"
      sched.statements.elements[2].content.text_value.should == "2. Bar"
    end

    it 'should handle many schedules' do
      node = parse :schedules, <<EOS
Schedule "1"
A Title
1. Foo
2. Bar
Schedule 2
Another Title
Baz
Boom
EOS

      sched = node.schedules.elements[0]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.schedule_heading.schedule_title.content.text_value.should == "A Title"
      sched.schedule_heading.num.text_value.should == "1"
      sched.statements.elements[0].content.text_value.should == "1. Foo"
      sched.statements.elements[1].content.text_value.should == "2. Bar"

      sched = node.schedules.elements[1]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.schedule_heading.schedule_title.content.text_value.should == "Another Title"
      sched.schedule_heading.num.text_value.should == "2"
      sched.statements.elements[0].content.text_value.should == "Baz"
      sched.statements.elements[1].content.text_value.should == "Boom"
    end

    it 'should serialise many schedules correctly' do
      node = parse :schedules, <<EOS
Schedule "2"
A Title
1. Foo
2. Bar
Schedule 3
Another Title
Baz
Boom
EOS

      s = ""
      builder = ::Builder::XmlMarkup.new(indent: 2, target: s)

      node.to_xml(builder)

      today = Time.now.strftime('%Y-%m-%d')

      s.should == <<EOS
<components>
  <component id="component-1">
    <doc name="schedule2">
      <meta>
        <identification source="#slaw">
          <FRBRWork>
            <FRBRthis value="/za/act/1980/01/schedule2"/>
            <FRBRuri value="/za/act/1980/01"/>
            <FRBRalias value="Schedule 2"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRcountry value="za"/>
          </FRBRWork>
          <FRBRExpression>
            <FRBRthis value="/za/act/1980/01/eng@/schedule2"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRlanguage language="eng"/>
          </FRBRExpression>
          <FRBRManifestation>
            <FRBRthis value="/za/act/1980/01/eng@/schedule2"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="#{today}" name="Generation"/>
            <FRBRauthor href="#slaw" as="#author"/>
          </FRBRManifestation>
        </identification>
      </meta>
      <mainBody>
        <article id="schedule-2">
          <heading>A Title</heading>
          <content>
            <p>1. Foo</p>
            <p>2. Bar</p>
          </content>
        </article>
      </mainBody>
    </doc>
  </component>
  <component id="component-2">
    <doc name="schedule3">
      <meta>
        <identification source="#slaw">
          <FRBRWork>
            <FRBRthis value="/za/act/1980/01/schedule3"/>
            <FRBRuri value="/za/act/1980/01"/>
            <FRBRalias value="Schedule 3"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRcountry value="za"/>
          </FRBRWork>
          <FRBRExpression>
            <FRBRthis value="/za/act/1980/01/eng@/schedule3"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRlanguage language="eng"/>
          </FRBRExpression>
          <FRBRManifestation>
            <FRBRthis value="/za/act/1980/01/eng@/schedule3"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="#{today}" name="Generation"/>
            <FRBRauthor href="#slaw" as="#author"/>
          </FRBRManifestation>
        </identification>
      </meta>
      <mainBody>
        <article id="schedule-3">
          <heading>Another Title</heading>
          <content>
            <p>Baz</p>
            <p>Boom</p>
          </content>
        </article>
      </mainBody>
    </doc>
  </component>
</components>
EOS

    end

    it 'should serialise a single schedule without a heading' do
      node = parse :schedules, <<EOS
Schedule "1"
Other than as is set out hereinbelow, no signs other than locality bound signs, temporary signs including loose portable sign, estate agents signs, newspaper headline posters and posters (the erection of which must comply with the appropriate schedules pertinent thereto) shall be erected on Municipal owned land.
1. Foo
2. Bar
EOS

      s = to_xml(node, 2)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == <<EOS
<components>
  <component id="component-1">
    <doc name="schedule1">
      <meta>
        <identification source="#slaw">
          <FRBRWork>
            <FRBRthis value="/za/act/1980/01/schedule1"/>
            <FRBRuri value="/za/act/1980/01"/>
            <FRBRalias value="Schedule 1"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRcountry value="za"/>
          </FRBRWork>
          <FRBRExpression>
            <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="1980-01-01" name="Generation"/>
            <FRBRauthor href="#council" as="#author"/>
            <FRBRlanguage language="eng"/>
          </FRBRExpression>
          <FRBRManifestation>
            <FRBRthis value="/za/act/1980/01/eng@/schedule1"/>
            <FRBRuri value="/za/act/1980/01/eng@"/>
            <FRBRdate date="#{today}" name="Generation"/>
            <FRBRauthor href="#slaw" as="#author"/>
          </FRBRManifestation>
        </identification>
      </meta>
      <mainBody>
        <article id="schedule-1">
          <content>
            <p>Other than as is set out hereinbelow, no signs other than locality bound signs, temporary signs including loose portable sign, estate agents signs, newspaper headline posters and posters (the erection of which must comply with the appropriate schedules pertinent thereto) shall be erected on Municipal owned land.</p>
            <p>1. Foo</p>
            <p>2. Bar</p>
          </content>
        </article>
      </mainBody>
    </doc>
  </component>
</components>
EOS
    end
  end

  describe 'tables' do
    it 'should parse basic tables' do
      node = parse :table, <<EOS
{|
| r1c1
| r1c2
|-
| r2c1
| r2c2
|}
EOS

      node.text_value.should == "{|\n| r1c1\n| r1c2\n|-\n| r2c1\n| r2c2\n|}\n"
      to_xml(node, nil, "prefix.").should == '<table id="prefix.table0"><tr><td><p>r1c1</p></td>
<td><p>r1c2</p></td></tr>
<tr><td><p>r2c1</p></td>
<td><p>r2c2</p></td></tr></table>'
    end

    it 'should parse a table in a section' do
      node = parse :section, <<EOS
10. A section title

Heres a table:

{|
| r1c1
| r1c2
|-
| r2c1
| r2c2
|}
EOS

      xml = to_xml(node)
      xml.should == '<section id="section-10"><num>10.</num><heading>A section title</heading><subsection id="section-10.subsection-0"><content><p>Heres a table:</p></content></subsection><subsection id="section-10.subsection-1"><content><table id="section-10.subsection-1.table0"><tr><td><p>r1c1</p></td>
<td><p>r1c2</p></td></tr>
<tr><td><p>r2c1</p></td>
<td><p>r2c2</p></td></tr></table></content></subsection></section>'
    end

    it 'should parse a table in a schedule' do
      node = parse :schedule, <<EOS
Schedule 1

Heres a table:

{|
| r1c1
| r1c2
|-
| r2c1
| r2c2
|}
EOS

      xml = to_xml(node, nil, "")
      today = Time.now.strftime('%Y-%m-%d')
      xml.should == '<doc name="schedule1"><meta><identification source="#slaw"><FRBRWork><FRBRthis value="/za/act/1980/01/schedule1"/><FRBRuri value="/za/act/1980/01"/><FRBRalias value="Schedule 1"/><FRBRdate date="1980-01-01" name="Generation"/><FRBRauthor href="#council" as="#author"/><FRBRcountry value="za"/></FRBRWork><FRBRExpression><FRBRthis value="/za/act/1980/01/eng@/schedule1"/><FRBRuri value="/za/act/1980/01/eng@"/><FRBRdate date="1980-01-01" name="Generation"/><FRBRauthor href="#council" as="#author"/><FRBRlanguage language="eng"/></FRBRExpression><FRBRManifestation><FRBRthis value="/za/act/1980/01/eng@/schedule1"/><FRBRuri value="/za/act/1980/01/eng@"/><FRBRdate date="' + today + '" name="Generation"/><FRBRauthor href="#slaw" as="#author"/></FRBRManifestation></identification></meta><mainBody><article id="schedule-1"><content><p>Heres a table:</p><table id="schedule-1.table0"><tr><td><p>r1c1</p></td>
<td><p>r1c2</p></td></tr>
<tr><td><p>r2c1</p></td>
<td><p>r2c2</p></td></tr></table></content></article></mainBody></doc>'
    end
  end
end
