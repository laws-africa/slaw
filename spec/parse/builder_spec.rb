# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::Parse::Builder do
  let(:parser) { double("parser") }
  subject { Slaw::Parse::Builder.new(parser: parser) }

  describe '#preprocess' do
    it 'should split inline table cells into block table cells' do
      text = <<EOS
foo
| bar || baz

{|
| boom || one !! two
|-
| three
|}

xxx

{|
| colspan="2" | bar || baz
|}
EOS
      subject.preprocess(text).should == <<EOS
foo
| bar || baz

{|
| boom 
| one 
! two
|-
| three
|}

xxx

{|
| colspan="2" | bar 
| baz
|}
EOS
    end
  end
end
