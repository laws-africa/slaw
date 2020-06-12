module Slaw
  AKN3_NS = 'http://docs.oasis-open.org/legaldocml/ns/akn/3.0'

  @@ns = AKN3_NS

  def self.akn_namespace
    @@ns
  end

  def self.akn_namespace=(ns)
    @@ns = ns
  end
end
