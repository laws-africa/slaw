require 'slaw/grammars/core_nodes'

module Slaw
  module Grammars
    module Schedules
      FRBR_URI = '/za/act/1980/01'
      WORK_URI = FRBR_URI
      EXPRESSION_URI = "#{FRBR_URI}/eng@"
      MANIFESTATION_URI = EXPRESSION_URI

      class ScheduleContainer < Treetop::Runtime::SyntaxNode
        def to_xml(b)
          b.components { |b| 
            schedules.children.elements.each_with_index { |e, i|
              e.to_xml(b, "", i+1)
            }
          }
        end
      end

      class Schedule < Treetop::Runtime::SyntaxNode
        def num
          n = schedule_title.num.text_value
          return (n && !n.empty?) ? n : nil
        end

        def alias
          if not schedule_title.title.text_value.blank?
            # plain-text elements only
            schedule_title.title.elements.select { |x| x.instance_of? ::Slaw::Grammars::Inlines::InlineItem }.map { |x| x.text_value }.join('').strip
          elsif num
            "Schedule #{num}"
          else
            "Schedule"
          end
        end

        def title
          if not schedule_title.title.text_value.blank?
            schedule_title.title
          else
            nil
          end
        end

        def subheading
          if not schedule_title.subheading.text_value.blank?
            schedule_title.subheading.inline_items
          else
            nil
          end
        end

        def to_xml(b, idprefix=nil, i=1)
          if num
            n = num
            component = "schedule#{n}"
          else
            n = i
            # make a component name from the schedule title
            component = self.alias.downcase().strip().gsub(/[^a-z0-9]/i, '').gsub(/ +/, '')
          end

          id = "#{idprefix}#{component}"

          b.component(id: "component-#{id}") { |b|
            b.doc_(name: component) { |b|
              b.meta { |b|
                b.identification(source: "#slaw") { |b|
                  b.FRBRWork { |b|
                    b.FRBRthis(value: "#{WORK_URI}/#{component}")
                    b.FRBRuri(value: WORK_URI)
                    b.FRBRalias(value: self.alias)
                    b.FRBRdate(date: '1980-01-01', name: 'Generation')
                    b.FRBRauthor(href: '#council')
                    b.FRBRcountry(value: 'za')
                  }
                  b.FRBRExpression { |b|
                    b.FRBRthis(value: "#{EXPRESSION_URI}/#{component}")
                    b.FRBRuri(value: EXPRESSION_URI)
                    b.FRBRdate(date: '1980-01-01', name: 'Generation')
                    b.FRBRauthor(href: '#council')
                    b.FRBRlanguage(language: 'eng')
                  }
                  b.FRBRManifestation { |b|
                    b.FRBRthis(value: "#{MANIFESTATION_URI}/#{component}")
                    b.FRBRuri(value: MANIFESTATION_URI)
                    b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
                    b.FRBRauthor(href: '#slaw')
                  }
                }
              }

              b.mainBody { |b| 
                idprefix = "#{id}."

                # there is no good AKN hierarchy container for schedules, so we
                # use hcontainer instead
                b.hcontainer(id: id, name: "schedule") { |b|
                  if title and title.elements
                    b.heading { |b| title.to_xml(b, idprefix) }
                  else
                    b.heading(self.alias)
                  end
                  b.subheading { |b| subheading.to_xml(b, idprefix) } if subheading
                  body.children.elements.each_with_index { |e| e.to_xml(b, idprefix, i) } if body.is_a? Body
                }
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
