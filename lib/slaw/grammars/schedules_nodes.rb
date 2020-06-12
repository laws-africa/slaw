require 'slaw/grammars/core_nodes'

module Slaw
  module Grammars
    module Schedules
      FRBR_URI = '/za/act/1980/01'
      WORK_URI = FRBR_URI
      EXPRESSION_URI = "#{FRBR_URI}/eng@"
      MANIFESTATION_URI = EXPRESSION_URI

      class ScheduleContainer < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix="")
          b.attachments { |b|
            schedules.children.elements.each_with_index { |e, i|
              e.to_xml(b, idprefix, i+1)
            }
          }
        end
      end

      class ScheduleTitle < Treetop::Runtime::SyntaxNode
        def heading_text
          if heading.empty? or heading.title.empty?
            nil
          else
            heading.title.elements
              .select { |x| x.instance_of? ::Slaw::Grammars::Inlines::InlineItem }
              .map { |x| x.text_value }
              .join('')
              .strip
          end
        end

        def to_xml(b, idprefix=nil, heading_text)
          if not heading.empty? and not heading.title.empty?
            b.heading { |b| heading.title.to_xml(b, idprefix) }
          else
            b.heading(heading_text)
          end

          if not subheading.empty? and not subheading.title.empty?
            b.subheading { |b| subheading.title.to_xml(b, idprefix) }
          end
        end
      end

      class LegacyScheduleTitle < Treetop::Runtime::SyntaxNode
        def heading_plain_text
          heading.elements
            .select { |x| x.instance_of? ::Slaw::Grammars::Inlines::InlineItem }
            .map { |x| x.text_value }
            .join('')
            .strip
        end

        def heading_text
          if heading.empty?
            nil
          else
            text = self.heading_plain_text

            # change legacy titles that are just numbers (eg. the "1" in "Schedule 1")
            # to "Schedule 1"
            text = "Schedule #{text}" if /^\d+$/.match?(text)

            text
          end
        end

        def to_xml(b, idprefix=nil, heading_text)
          if not heading.empty? and not (/^\d+$/.match?(self.heading_plain_text))
            b.heading { |b| heading.to_xml(b, idprefix) }
          else
            b.heading(heading_text)
          end

          if not subheading.empty?
            b.subheading { |b| subheading.inline_items.to_xml(b, idprefix) }
          end
        end
      end

      class Schedule < Treetop::Runtime::SyntaxNode
        def schedule_id(heading_text, i)
          heading_text.downcase().strip().gsub(/[^a-z0-9]/i, '').gsub(/ +/, '')
        end

        def to_xml(b, idprefix=nil, i=1)
          # reset counters for this new schedule document
          Slaw::Grammars::Counters.reset!

          heading_text = self.schedule_title.heading_text
          if not heading_text
            heading_text = "Schedule"
            heading_text << " #{i}" if i > 1
          end

          # the schedule id is derived from the heading
          schedule_id = self.schedule_id(heading_text, i)

          b.attachment(eId: "att_#{i}") { |b|
            schedule_title.to_xml(b, '', heading_text)
            b.doc_(name: "schedule") { |b|
              b.meta { |b|
                b.identification(source: "#slaw") { |b|
                  b.FRBRWork { |b|
                    b.FRBRthis(value: "#{WORK_URI}/!#{schedule_id}")
                    b.FRBRuri(value: WORK_URI)
                    b.FRBRalias(value: heading_text)
                    b.FRBRdate(date: '1980-01-01', name: 'Generation')
                    b.FRBRauthor(href: '#council')
                    b.FRBRcountry(value: 'za')
                  }
                  b.FRBRExpression { |b|
                    b.FRBRthis(value: "#{EXPRESSION_URI}/!#{schedule_id}")
                    b.FRBRuri(value: EXPRESSION_URI)
                    b.FRBRdate(date: '1980-01-01', name: 'Generation')
                    b.FRBRauthor(href: '#council')
                    b.FRBRlanguage(language: 'eng')
                  }
                  b.FRBRManifestation { |b|
                    b.FRBRthis(value: "#{MANIFESTATION_URI}/!#{schedule_id}")
                    b.FRBRuri(value: MANIFESTATION_URI)
                    b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
                    b.FRBRauthor(href: '#slaw')
                  }
                }
              }

              b.mainBody { |b| 
                body.children.elements.each_with_index { |e| e.to_xml(b, '', i) } if body.is_a? Body
              }
            }
          }
        end
      end

      class ScheduleStatement < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.p { |b| inline_items.to_xml(b, idprefix) } if inline_items
        end
      end
    end
  end
end
