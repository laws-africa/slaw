require 'xml_helpers'

RSpec.configure do |config|
  # use old-style foo.should == 'foo' syntax
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
