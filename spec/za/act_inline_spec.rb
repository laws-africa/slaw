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

  def to_xml(node, *args)
    b = ::Nokogiri::XML::Builder.new
    node.to_xml(b, *args)
    b.doc.root.to_xml(encoding: 'UTF-8')
  end

  #-------------------------------------------------------------------------------
  # Remarks

  describe 'remark' do
    it 'should handle a plain remark' do
      node = parse :block_paragraphs, <<EOS
      [[Section 2 amended by Act 23 of 2004]]
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>
      <remark status="editorial">[Section 2 amended by Act 23 of 2004]</remark>
    </p>
  </content>
</paragraph>'
    end

    it 'should handle an inline remark at the end of a sentence' do
      node = parse :block_paragraphs, <<EOS
      This statement has an inline remark. [[Section 2 amended by Act 23 of 2004]]
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>This statement has an inline remark. <remark status="editorial">[Section 2 amended by Act 23 of 2004]</remark></p>
  </content>
</paragraph>'
    end

    it 'should handle an inline remark mid-way through' do
      node = parse :subsection, <<EOS
      (1) This statement has an inline remark. [[Section 2 amended by Act 23 of 2004]] And now some more.
EOS
      to_xml(node, "", 1).should == '<subsection id="1">
  <num>(1)</num>
  <content>
    <p>This statement has an inline remark. <remark status="editorial">[Section 2 amended by Act 23 of 2004]</remark> And now some more.</p>
  </content>
</subsection>'
    end

    it 'should handle many inline remarks' do
      node = parse :block_paragraphs, <<EOS
      This statement has an inline remark. [[Section 2 amended by Act 23 of 2004]]. And now some more. [[Another remark]] [[and another]]
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>This statement has an inline remark. <remark status="editorial">[Section 2 amended by Act 23 of 2004]</remark>. And now some more. <remark status="editorial">[Another remark]</remark> <remark status="editorial">[and another]</remark></p>
  </content>
</paragraph>'
    end

    it 'should handle a remark in a section' do
      node = parse :section, <<EOS
      1. Section title
      Some text is a long line.

      [[Section 1 amended by Act 23 of 2004]]
EOS
      to_xml(node).should == '<section id="section-1">
  <num>1.</num>
  <heading>Section title</heading>
  <paragraph id="section-1.paragraph-0">
    <content>
      <p>Some text is a long line.</p>
      <p>
        <remark status="editorial">[Section 1 amended by Act 23 of 2004]</remark>
      </p>
    </content>
  </paragraph>
</section>'
    end

    it 'should handle a remark in a blocklist' do
      node = parse :section, <<EOS
      1. Section title
      Some text is a long line.

      (1) something
      (a) with a remark [[Section 1 amended by Act 23 of 2004]]
EOS
      to_xml(node).should == '<section id="section-1">
  <num>1.</num>
  <heading>Section title</heading>
  <paragraph id="section-1.paragraph-0">
    <content>
      <p>Some text is a long line.</p>
    </content>
  </paragraph>
  <subsection id="section-1.1">
    <num>(1)</num>
    <content>
      <p>something</p>
      <blockList id="section-1.1.list1">
        <item id="section-1.1.list1.a">
          <num>(a)</num>
          <p>with a remark <remark status="editorial">[Section 1 amended by Act 23 of 2004]</remark></p>
        </item>
      </blockList>
    </content>
  </subsection>
</section>'
    end

    it 'should handle a remark in a schedule' do
      node = parse :schedule, <<EOS
      Schedule 1
      A Title

      [[Schedule 1 added by Act 23 of 2004]]

      Some content
EOS

      today = Time.now.strftime('%Y-%m-%d')
      to_xml(node, "").should == '<component id="component-schedule1">
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
          <FRBRdate date="' + today + '" name="Generation"/>
          <FRBRauthor href="#slaw"/>
        </FRBRManifestation>
      </identification>
    </meta>
    <mainBody>
      <article id="schedule1">
        <heading>A Title</heading>
        <paragraph id="schedule1.paragraph-0">
          <content>
            <p>
              <remark status="editorial">[Schedule 1 added by Act 23 of 2004]</remark>
            </p>
            <p>Some content</p>
          </content>
        </paragraph>
      </article>
    </mainBody>
  </doc>
</component>'
    end
  end

  #-------------------------------------------------------------------------------
  # Refs

  describe 'ref' do
    it 'should handle a plain ref' do
      node = parse :block_paragraphs, <<EOS
      Hello [there](/za/act/123) friend.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <ref href="/za/act/123">there</ref> friend.</p>
  </content>
</paragraph>'
    end

    it 'should work many on a line' do
      node = parse :block_paragraphs, <<EOS
      Hello [there](/za/act/123) friend [and](http://foo.bar.com/with space) you too.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <ref href="/za/act/123">there</ref> friend <ref href="http://foo.bar.com/with space">and</ref> you too.</p>
  </content>
</paragraph>'
    end

    it 'should handle brackets' do
      node = parse :block_paragraphs, <<EOS
      Hello ([there](/za/act/123)).
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello (<ref href="/za/act/123">there</ref>).</p>
  </content>
</paragraph>'
    end

    it 'should handle many clauses on a line' do
      node = parse :block_paragraphs, <<EOS
      Hello [there](/za/act/123)[[remark one]] my[friend](/za) [[remark 2]][end](/foo).
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <ref href="/za/act/123">there</ref><remark status="editorial">[remark one]</remark> my<ref href="/za">friend</ref> <remark status="editorial">[remark 2]</remark><ref href="/foo">end</ref>.</p>
  </content>
</paragraph>'
    end

    it 'text should not cross end of line' do
      node = parse :block_paragraphs, <<EOS
      Hello [there
      
      my](/za/act/123) friend.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello [there</p>
    <p>my](/za/act/123) friend.</p>
  </content>
</paragraph>'
    end

    it 'href should not cross end of line' do
      node = parse :block_paragraphs, <<EOS
      Hello [there](/za/act
      /123) friend.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello [there](/za/act</p>
    <p>/123) friend.</p>
  </content>
</paragraph>'
    end

    it 'href should handle refs in a list' do
      node = parse :block_paragraphs, <<EOS
      2.18.1 a traffic officer appointed in terms of section 3 of the Road Traffic [Act, No. 29 of 1989](/za/act/1989/29) or section 3A of the National Road Traffic [Act No. 93 of 1996](/za/act/1996/93) as the case may be;
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <blockList id="paragraph-0.list0">
      <item id="paragraph-0.list0.2.18.1">
        <num>2.18.1</num>
        <p>a traffic officer appointed in terms of section 3 of the Road Traffic <ref href="/za/act/1989/29">Act, No. 29 of 1989</ref> or section 3A of the National Road Traffic <ref href="/za/act/1996/93">Act No. 93 of 1996</ref> as the case may be;</p>
      </item>
    </blockList>
  </content>
</paragraph>'
    end
  end

end
