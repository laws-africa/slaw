# Add some helper methods to XML node objects
class Nokogiri::XML::Node

  # The AkomaNtoso number of this node, or nil if unknown.
  # Major AN elements such as chapters, parts and sections almost
  # always have numbers.
  def num
    node = at_xpath('./a:num', a: Slaw::NS)
    node ? node.text.gsub(/\.$/, '') : nil
  end
end
