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
  # schedules
  #
  context 'schedules' do
    it 'should serialise many schedules correctly' do
      node = parse :schedules_container, <<EOS
SCHEDULE

HEADING Schedule 2

SUBHEADING A Title


1. Foo
2. Bar
SCHEDULE
HEADING Schedule 3
SUBHEADING Another Title
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
        <hcontainer id="schedule2" name="schedule">
          <heading>Schedule 2</heading>
          <subheading>A Title</subheading>
          <section id="section-1">
            <num>1.</num>
            <heading>Foo</heading>
          </section>
          <section id="section-2">
            <num>2.</num>
            <heading>Bar</heading>
          </section>
        </hcontainer>
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
        <hcontainer id="schedule3" name="schedule">
          <heading>Schedule 3</heading>
          <subheading>Another Title</subheading>
          <paragraph id="schedule3.paragraph0">
            <content>
              <p>Baz</p>
              <p>Boom</p>
            </content>
          </paragraph>
        </hcontainer>
      </mainBody>
    </doc>
  </component>
</components>
EOS
    .strip

    end

    it 'should handle a schedule with a heading and a subheading' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING First Schedule
SUBHEADING Schedule Heading

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
      <hcontainer id="firstschedule" name="schedule">
        <heading>First Schedule</heading>
        <subheading>Schedule Heading</subheading>
        <paragraph id="firstschedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule with dot in the number' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING 1. First Schedule
SUBHEADING Schedule Heading

Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS
      s = to_xml(node)
      today = Time.now.strftime('%Y-%m-%d')
      s.should == '<component id="component-1firstschedule">
  <doc name="1firstschedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="1. First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <hcontainer id="1firstschedule" name="schedule">
        <heading>1. First Schedule</heading>
        <subheading>Schedule Heading</subheading>
        <paragraph id="1firstschedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule with a title' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING First Schedule

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
      <hcontainer id="firstschedule" name="schedule">
        <heading>First Schedule</heading>
        <paragraph id="firstschedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should support rich parts, chapters and sections in a schedule' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING Schedule 1
SUBHEADING Forms

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
      <hcontainer id="schedule1" name="schedule">
        <heading>Schedule 1</heading>
        <subheading>Forms</subheading>
        <part id="schedule1.part-I">
          <num>I</num>
          <heading>Form of authentication statement</heading>
          <paragraph id="schedule1.part-I.paragraph0">
            <content>
              <p>This printed impression has been carefully compared by me with the bill which was passed by Parliament and found by me to be a true copy of the bill.</p>
            </content>
          </paragraph>
        </part>
        <part id="schedule1.part-II">
          <num>II</num>
          <heading>Form of statement of the President’s assent.</heading>
          <paragraph id="schedule1.part-II.paragraph0">
            <content>
              <p>I signify my assent to the bill and a whole bunch of other stuff.</p>
            </content>
          </paragraph>
        </part>
      </hcontainer>
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
      <hcontainer id="schedule" name="schedule">
        <heading>Schedule</heading>
        <paragraph id="schedule.paragraph0">
          <content>
            <p>Subject to approval in terms of this By-Law.</p>
            <p>Schedule another</p>
            <p>More stuff</p>
          </content>
        </paragraph>
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle rich content in titles and subheandings' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING First Schedule [[remark]]
SUBHEADING Subheading [[another]]

Subject to approval in terms of this By-Law.
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
      <hcontainer id="firstschedule" name="schedule">
        <heading>First Schedule <remark status="editorial">[remark]</remark></heading>
        <subheading>Subheading <remark status="editorial">[another]</remark></subheading>
        <paragraph id="firstschedule.paragraph0">
          <content>
            <p>Subject to approval in terms of this By-Law.</p>
          </content>
        </paragraph>
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule without a heading' do
      node = parse :schedules, <<EOS
SCHEDULE
SUBHEADING Subheading

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
      <hcontainer id="schedule" name="schedule">
        <heading>Schedule</heading>
        <subheading>Subheading</subheading>
        <paragraph id="schedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

    it 'should handle a schedule with an empty heading and subheading' do
      node = parse :schedules, <<EOS
SCHEDULE
HEADING
SUBHEADING

Subject to approval in terms of this By-Law, the erection:
1. Foo
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
      <hcontainer id="schedule" name="schedule">
        <heading>Schedule</heading>
        <paragraph id="schedule.paragraph0">
          <content>
            <p>Subject to approval in terms of this By-Law, the erection:</p>
          </content>
        </paragraph>
        <section id="section-1">
          <num>1.</num>
          <heading>Foo</heading>
        </section>
      </hcontainer>
    </mainBody>
  </doc>
</component>'
    end

  end

  context 'legacy schedules' do
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
      <hcontainer id="schedule" name="schedule">
        <heading>Schedule</heading>
        <paragraph id="schedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
      end

      it 'should serialise many schedules correctly' do
        node = parse :schedules_container, <<EOS
Schedule 2
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
        <hcontainer id="schedule2" name="schedule">
          <heading>Schedule 2</heading>
          <subheading>A Title</subheading>
          <section id="section-1">
            <num>1.</num>
            <heading>Foo</heading>
          </section>
          <section id="section-2">
            <num>2.</num>
            <heading>Bar</heading>
          </section>
        </hcontainer>
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
        <hcontainer id="schedule3" name="schedule">
          <heading>Schedule 3</heading>
          <subheading>Another Title</subheading>
          <paragraph id="schedule3.paragraph0">
            <content>
              <p>Baz</p>
              <p>Boom</p>
            </content>
          </paragraph>
        </hcontainer>
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
        s.should == '<component id="component-1firstschedule">
  <doc name="1firstschedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="1 - First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <hcontainer id="1firstschedule" name="schedule">
        <heading>1 - First Schedule</heading>
        <subheading>Schedule Heading</subheading>
        <paragraph id="1firstschedule.paragraph0">
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
      </hcontainer>
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
        s.should == '<component id="component-1firstschedule">
  <doc name="1firstschedule">
    <meta>
      <identification source="#slaw">
        <FRBRWork>
          <FRBRthis value="/za/act/1980/01/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01"/>
          <FRBRalias value="1. First Schedule"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/act/1980/01/eng@/1firstschedule"/>
          <FRBRuri value="/za/act/1980/01/eng@"/>
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <hcontainer id="1firstschedule" name="schedule">
        <heading>1. First Schedule</heading>
        <subheading>Schedule Heading</subheading>
        <paragraph id="1firstschedule.paragraph0">
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
      </hcontainer>
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
      <hcontainer id="firstschedule" name="schedule">
        <heading>First Schedule</heading>
        <paragraph id="firstschedule.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>'
      end

      it 'should serialise a single schedule without a heading' do
        node = parse :schedules, <<EOS
Schedule 1

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
      <hcontainer id="schedule1" name="schedule">
        <heading>Schedule 1</heading>
        <paragraph id="schedule1.paragraph0">
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
      </hcontainer>
    </mainBody>
  </doc>
</component>
EOS
        .strip
      end

      it 'should handle rich content in titles and subheandings' do
        node = parse :schedules, <<EOS
Schedule - First Schedule [[remark]]
Subheading [[another]]

Subject to approval in terms of this By-Law.
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
      <hcontainer id="firstschedule" name="schedule">
        <heading>First Schedule <remark status="editorial">[remark]</remark></heading>
        <subheading>Subheading <remark status="editorial">[another]</remark></subheading>
        <paragraph id="firstschedule.paragraph0">
          <content>
            <p>Subject to approval in terms of this By-Law.</p>
          </content>
        </paragraph>
      </hcontainer>
    </mainBody>
  </doc>
</component>'
      end

    end
  end
end
