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
      <hcontainer id="schedule1" name="schedule">
        <heading>Schedule 1</heading>
        <subheading>A Title</subheading>
        <paragraph id="schedule1.paragraph-0">
          <content>
            <p>
              <remark status="editorial">[Schedule 1 added by Act 23 of 2004]</remark>
            </p>
            <p>Some content</p>
          </content>
        </paragraph>
      </hcontainer>
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

    it 'should handle a link in an inline remark' do
      node = parse :block_paragraphs, <<EOS
      This statement has [[a [link in](/foo/bar) a remark]]
      This statement has [[[a link in](/foo/bar) a remark]]
      This statement has [[a [link in a remark](/foo/bar)]]
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>This statement has <remark status="editorial">[a <ref href="/foo/bar">link in</ref> a remark]</remark></p>
    <p>This statement has <remark status="editorial">[<ref href="/foo/bar">a link in</ref> a remark]</remark></p>
    <p>This statement has <remark status="editorial">[a <ref href="/foo/bar">link in a remark</ref>]</remark></p>
  </content>
</paragraph>'
    end
  end

  #-------------------------------------------------------------------------------
  # images

  describe 'images' do
    it 'should handle a simple image' do
      node = parse :block_paragraphs, <<EOS
      Hello ![title](media/foo.png) friend.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <img src="media/foo.png" alt="title"/> friend.</p>
  </content>
</paragraph>'
    end

    it 'should work many on a line' do
      node = parse :block_paragraphs, <<EOS
      Hello ![title](media/foo.png) friend and ![](media/bar.png) a second.
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <img src="media/foo.png" alt="title"/> friend and <img src="media/bar.png"/> a second.</p>
  </content>
</paragraph>'
    end
  end

  #-------------------------------------------------------------------------------
  # inline statements

  context 'inline_statements' do
    it 'should handle less-than-chars' do
      node = parse :inline_statement, <<EOS
Hello 1 < 2 and 3 > 2
EOS
      to_xml(node, "").should == '<p>Hello 1 &lt; 2 and 3 &gt; 2</p>'
    end

    it 'should handle html-like text' do
      node = parse :inline_statement, <<EOS
Stuff <between> angles
EOS
      to_xml(node, "").should == '<p>Stuff &lt;between&gt; angles</p>'
    end
  end

  #-------------------------------------------------------------------------------
  # italics and bold

  describe 'bold' do
    it 'should handle simple bold' do
      node = parse :block_paragraphs, <<EOS
      Hello **something bold** foo
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <b>something bold</b> foo</p>
  </content>
</paragraph>'
    end

    it 'should handle complex bold' do
      node = parse :block_paragraphs, <<EOS
      A [**link**](/a/b) with bold
      This is **bold with [a link](/a/b)** end
      This is **bold //italics [a link](/a/b)//** end
      A **[link**](/a/b)**
      A **[link**](/a/b)
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>A <ref href="/a/b"><b>link</b></ref> with bold</p>
    <p>This is <b>bold with <ref href="/a/b">a link</ref></b> end</p>
    <p>This is <b>bold <i>italics <ref href="/a/b">a link</ref></i></b> end</p>
    <p>A <b>[link</b>](/a/b)**</p>
    <p>A **<ref href="/a/b">link**</ref></p>
  </content>
</paragraph>'
    end

    it 'should not mistake bold' do
      node = parse :block_paragraphs, <<EOS
      Hello **something
      New line**
      **New line
      ****
      **
      *
      * * foo **
      * * foo * *
      ** foo * *
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello **something</p>
    <p>New line**</p>
    <p>**New line</p>
    <p>****</p>
    <p>**</p>
    <p>*</p>
    <p>* * foo **</p>
    <p>* * foo * *</p>
    <p>** foo * *</p>
  </content>
</paragraph>'
    end
  end

  describe 'italics' do
    it 'should handle simple italics' do
      node = parse :block_paragraphs, <<EOS
      Hello //something italics// foo
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello <i>something italics</i> foo</p>
  </content>
</paragraph>'
    end

    it 'should handle complex italics' do
      node = parse :block_paragraphs, <<EOS
      A [//link//](/a/b) with italics
      This is //italics with [a link](/a/b)// end
      A //italics**bold//**
      A **bold//italics**//
      A //[link//](/a/b)//
      A //[link//](/a/b)
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>A <ref href="/a/b"><i>link</i></ref> with italics</p>
    <p>This is <i>italics with <ref href="/a/b">a link</ref></i> end</p>
    <p>A //italics<b>bold//</b></p>
    <p>A **bold<i>italics**</i></p>
    <p>A <i>[link</i>](/a/b)//</p>
    <p>A //<ref href="/a/b">link//</ref></p>
  </content>
</paragraph>'
    end

    it 'should not mistake italics' do
      node = parse :block_paragraphs, <<EOS
      Hello //something
      New line//
      //New line
      ////
      //
      /
      / / foo //
      / / foo / /
      // foo / /
EOS
      to_xml(node, "").should == '<paragraph id="paragraph-0">
  <content>
    <p>Hello //something</p>
    <p>New line//</p>
    <p>//New line</p>
    <p>////</p>
    <p>//</p>
    <p>/</p>
    <p>/ / foo //</p>
    <p>/ / foo / /</p>
    <p>// foo / /</p>
  </content>
</paragraph>'
    end
  end

end
