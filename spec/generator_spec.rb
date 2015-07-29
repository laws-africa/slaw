# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::ActGenerator do
  describe 'guess_section_number_after_title' do
    context 'section number after title' do
      it 'should work' do
        text = "
Section title
1. Section content

Another section title
2. Section content that is long.
"
        subject.guess_section_number_after_title(text).should be_true
      end
    end

    context 'section number before title' do
      it 'should default to false' do
        subject.guess_section_number_after_title("").should be_false
      end

      it 'should be false' do
        text = "
Mistaken title
1. Section title

Some content.

2. Second title

Some content.
"
        subject.guess_section_number_after_title(text).should be_false
      end
    end
  end
end
