# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::Act do
  let(:filename) { File.dirname(__FILE__) + "/fixtures/community-fire-safety.xml" }
  subject { Slaw::Act.new(filename) }

  it 'should have correct basic properties' do
    subject.title.should == 'Community Fire Safety By-law'
    subject.amended?.should be_true
  end

  it 'should set the title correctly' do
    subject.title = 'foo'
    subject.meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: Slaw::NS)['value'].should == 'foo'
  end

  it 'should set the title if it doesnt exist' do
    subject.meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRalias', a: Slaw::NS).remove
    subject.title = 'bar'
    subject.title.should == 'bar'
  end

  it 'should set the publication details' do
    subject.meta.at_xpath('./a:publication', a: Slaw::NS).remove

    subject.published!(name: 'foo', number: '1234', date: '2014-01-01')
    subject.publication['name'].should == 'foo'
    subject.publication['showAs'].should == 'foo'
    subject.publication['number'].should == '1234'
  end

  it 'should get/set the work date' do
    subject.date.should == '2002-02-28'

    subject.date = '2014-01-01'
    subject.date.should == '2014-01-01'
    subject.meta.at_xpath('./a:identification/a:FRBRWork/a:FRBRdate[@name="Generation"]', a: Slaw::NS)['date'].should == '2014-01-01'
    subject.meta.at_xpath('./a:identification/a:FRBRExpression/a:FRBRdate[@name="Generation"]', a: Slaw::NS)['date'].should == '2014-01-01'

    subject.id_uri.should == '/za/by-law/2014/2002'
  end

  it 'should update the uri when the year changes' do
    subject.id_uri.should == '/za/by-law/cape-town/2002/community-fire-safety'
    subject.year = '1980'
    subject.id_uri.should == '/za/by-law/1980/2002'
  end

  it 'should validate' do
    subject.validate.should == []
    subject.validates?.should be_true
  end
end
