# encoding: UTF-8

require 'slaw'
require 'slaw/grammars/za/postprocess'

describe Slaw::Grammars::ZA::Postprocess do
  subject { 
    class Subject
      include Slaw::Grammars::ZA::Postprocess
    end.new
  }
  context 'schedule_aliases' do
    it 'should include all text in schedule aliases' do
      xml = '
<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
  <components>
    <component id="component-firstschedule">
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
              <FRBRdate date="2019-01-01" name="Generation"/>
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
    </component>
  </components>
</akomaNtoso>'
      doc = xml2doc(xml)
      subject.schedule_aliases(doc)

      doc.xpath('//xmlns:doc/xmlns:meta//xmlns:FRBRWork/xmlns:FRBRalias')[0]['value'].should == 'First Schedule [remark]'
    end

    it 'should have a decent alias when there is an empty heading' do
      xml = '
<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
  <components>
    <component id="component-firstschedule">
      <doc name="firstschedule">
        <meta>
          <identification source="#slaw">
            <FRBRWork>
              <FRBRthis value="/za/act/1980/01/firstschedule"/>
              <FRBRuri value="/za/act/1980/01"/>
              <FRBRalias value="Schedule"/>
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
              <FRBRdate date="2019-01-01" name="Generation"/>
              <FRBRauthor href="#slaw"/>
            </FRBRManifestation>
          </identification>
        </meta>
        <mainBody>
          <hcontainer id="firstschedule" name="schedule">
            <heading/>
            <subheading>Subheading <remark status="editorial">[another]</remark></subheading>
            <paragraph id="firstschedule.paragraph0">
              <content>
                <p>Subject to approval in terms of this By-Law.</p>
              </content>
            </paragraph>
          </hcontainer>
        </mainBody>
      </doc>
    </component>
  </components>
</akomaNtoso>'
      doc = xml2doc(xml)
      subject.schedule_aliases(doc)

      doc.xpath('//xmlns:doc/xmlns:meta//xmlns:FRBRWork/xmlns:FRBRalias')[0]['value'].should == 'Schedule'
    end
  end
end
