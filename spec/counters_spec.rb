# encoding: UTF-8

require 'spec_helper'

require 'slaw'

describe Slaw::Grammars::Counters do
  describe '#clean' do
    it 'should remove leading and trailing punctuation' do
      described_class.clean("").should == ""
      described_class.clean(" ").should == ""
      described_class.clean("( )").should == ""
      described_class.clean("(123.4-5)").should == "123-4-5"
      described_class.clean("(312.32.7)").should == "312-32-7"
      described_class.clean("(312_32_7)").should == "312-32-7"
      described_class.clean("(6)").should == "6"
      described_class.clean("[16]").should == "16"
      described_class.clean("(i)").should == "i"
      described_class.clean("[i]").should == "i"
      described_class.clean("(2bis)").should == "2bis"
      described_class.clean('"1.2.').should == "1-2"
      described_class.clean("1.2.").should == "1-2"
      described_class.clean("“2.3").should == "2-3"
      described_class.clean("2,3").should == "2-3"
      described_class.clean("2,3, 4,").should == "2-3-4"
      described_class.clean("3a bis").should == "3abis"
      described_class.clean("3é").should == "3é"
      described_class.clean(" -3a--4,9").should == "3a-4-9"
    end

    it 'should handle non-arabic numerals' do
      # hebrew aleph
      described_class.clean("(א)").should == "א"
      # chinese 3
      described_class.clean("(三)").should == "三"
    end
  end
end
