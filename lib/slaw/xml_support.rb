# Add some helper methods to XML node objects
class Nokogiri::XML::Node

  # The AkomaNtoso number of this node, or nil if unknown.
  # Major AN elements such as chapters, parts and sections almost
  # always have numbers.
  def num
    node = at_xpath('./a:num', a: Slaw::NS)
    node ? node.text.gsub(/\.$/, '') : nil
  end

  def heading
    node = at_xpath('./a:heading', a: Slaw::NS)
    node ? node.text : nil
  end

  def id
    self['id']
  end

  def chapters
    xpath('./a:chapter', a: Slaw::NS)
  end

  def sections
    xpath('./a:section', a: Slaw::NS)
  end

  def parts
    xpath('./a:part', a: Slaw::NS)
  end

  # Get a nodeset of child elements of this node which should show
  # up in the table of contents
  def toc_children
    if in_schedules?
      # in schedules, we only care about chapters that have numbers in them, because we
      # can't link to them otherwise
      xpath('a:chapter[a:num]', a: Slaw::NS)
    else
      xpath('a:part | a:chapter | a:section', a: Slaw::NS)
    end
  end

  # Does this element hold children for the table of contents?
  def toc_container?
    !toc_children.empty?
  end

  # Title for this element in the table of contents
  def toc_title
    case name
    when "mainBody"
      "Schedules"
    when "chapter"
      title = in_schedules? ? "Schedule" : "Chapter" 
      title << ' ' + num
      title << ' - ' + heading if heading
      title
    when "part"
      "Part #{num} - #{heading}"
    when "section"
      if not heading or heading.empty?
        "Section #{num}" 
      elsif num
        "#{num}. #{heading}"
      else
        heading
      end
    end        
  end

  # Is this element part of a schedule document?
  def in_schedules?
    not ancestors('doc[name="schedules"]').empty?
  end
end
