# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::ByLaw do
  let(:filename) { File.dirname(__FILE__) + "/fixtures/community-fire-safety.xml" }
  subject { Slaw::ByLaw.new(filename) }

  it 'should have correct basic properties' do
    subject.title.should == 'Community Fire Safety By-law as amended'
    subject.amended?.should be_true
  end

  it 'should set the title correctly' do
    subject.title = 'foo'
    subject.meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: Slaw::NS)['value'].should == 'foo'
  end

  it 'should set the title if it doesnt exist' do
    subject.meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: Slaw::NS).remove
    subject.title = 'bar'
    subject.title.should == 'bar as amended'
  end

  it 'should set the publication details' do
    subject.meta.at_xpath('./a:publication', a: Slaw::NS).remove

    subject.published!(name: 'foo', number: '1234', date: '2014-01-01')
    subject.publication['name'].should == 'foo'
    subject.publication['showAs'].should == 'foo'
    subject.publication['number'].should == '1234'
  end
end
