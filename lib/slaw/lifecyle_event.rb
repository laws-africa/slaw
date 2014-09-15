require 'slaw/namespace'

module Slaw
  # An event in the lifecycle of an act
  class LifecycleEvent
    include Slaw::Namespace

    # Date of the event
    attr_accessor :date

    # type of the event
    attr_accessor :type

    # the source of the event, an XML reference element
    attr_accessor :source

    def initialize(element)
      @date = element['date']
      @type = element['type']

      source_id = element['source'][1..-1]
      @source = element.document.at_xpath("//a:references/*[@id=\"#{source_id}\"]", a: NS)
    end
  end
end
