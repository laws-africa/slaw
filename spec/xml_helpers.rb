def xml2doc(xml)
  Nokogiri::XML(xml, &:noblanks)
end

def subsection(xml)
  pre = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
  <act contains="singleVersion">
    <body>
      <section id="section-10">
        <num>10.</num>
        <heading>Effect of order for <term refersTo="#term-eviction" id="trm236">eviction</term></heading>
        <subsection id="section-10.1">
          <num>(1)</num>
          <content>
XML
  post = <<XML
          </content>
        </subsection>
      </section>
    </body>
  </act>
</akomaNtoso>
XML

  return pre + xml + post
end

def section(xml)
  pre = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
  <act contains="singleVersion">
    <body>
      <section id="section-10">
XML
  post = <<XML
      </section>
    </body>
  </act>
</akomaNtoso>
XML

  return pre + xml + post
end
