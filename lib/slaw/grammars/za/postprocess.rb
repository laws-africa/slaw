require 'slaw/parse/blocklists'

module Slaw
  module Grammars
    module ZA
      module Postprocess
        def postprocess(doc)
          Slaw::Parse::Blocklists.adjust_blocklists(doc)
          schedule_aliases(doc)
          doc
        end

        # Correct aliases for schedules to use the full textual content of the heading element
        def schedule_aliases(doc)
          for hcontainer in doc.xpath('//xmlns:doc/xmlns:mainBody/xmlns:hcontainer[@name="schedule"]')
            heading = hcontainer.at_xpath('./xmlns:heading')
            frbr_alias = hcontainer.at_xpath('../../xmlns:meta/xmlns:identification/xmlns:FRBRWork/xmlns:FRBRalias')

            if heading and frbr_alias
              text = heading.xpath('.//text()').map(&:text).join('') || frbr_alias['value']
              frbr_alias['value'] = text unless text.empty?
            end
          end
        end
      end
    end
  end
end
