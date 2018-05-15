# encoding: UTF-8

require 'spec_helper'

require 'slaw'

describe Slaw::Parse::Cleanser do
  describe '#remove_empty_lines' do
    it 'should remove empty lines' do
      subject.remove_empty_lines("foo\n  \n\n  bar\n\n\nbaz\n").should == "foo\n  bar\nbaz"
    end
  end

  describe '#expand_tabs' do
    it 'should expand nbsp' do
      subject.expand_tabs("foo \u00A0bar").should == "foo  bar"
    end
  end
end
