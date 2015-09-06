require 'tempfile'

require 'spec_helper'
require 'slaw'

describe Slaw::Extract::Extractor do
  it 'should extract from plain text' do
    f = Tempfile.new(['test', '.txt'])
    f.write('This is some text')
    f.rewind

    subject.extract_from_file(f.path).should == "This is some text"
  end
end
