module Slaw
  AKN2_NS = 'http://www.akomantoso.org/2.0'
  AKN3_NS = 'http://docs.oasis-open.org/legaldocml/ns/akn/3.0'

  @@ns = AKN2_NS

  def self.akn_namespace
    @@ns
  end

  def self.akn_namespace=(ns)
    @@ns = ns
  end
end
