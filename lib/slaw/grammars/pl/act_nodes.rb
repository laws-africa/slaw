require 'slaw/grammars/core_nodes'

module Slaw
  module Grammars
    module PL
      module Act
        class Act < Treetop::Runtime::SyntaxNode
          FRBR_URI = '/pl/act/1980/01'
          WORK_URI = FRBR_URI
          EXPRESSION_URI = "#{FRBR_URI}/pol@"
          MANIFESTATION_URI = EXPRESSION_URI

          def to_xml(b, idprefix=nil, i=0)
            b.act(contains: "originalVersion") { |b|
              write_meta(b)
              write_preface(b)
              write_preamble(b)
              write_body(b)
            }
            write_schedules(b)
          end

          def write_meta(b)
            b.meta { |b|
              write_identification(b)

              b.references(source: "#this") {
                b.TLCOrganization(id: 'slaw', href: 'https://github.com/longhotsummer/slaw', showAs: "Slaw")
                b.TLCOrganization(id: 'council', href: '/ontology/organization/za/council', showAs: "Council")
              }
            }
          end

          def write_identification(b)
            b.identification(source: "#slaw") { |b|
              # use stub values so that we can generate a validating document
              b.FRBRWork { |b|
                b.FRBRthis(value: "#{WORK_URI}/main")
                b.FRBRuri(value: WORK_URI)
                b.FRBRalias(value: 'Short Title')
                b.FRBRdate(date: '1980-01-01', name: 'Generation')
                b.FRBRauthor(href: '#council')
                b.FRBRcountry(value: 'za')
              }
              b.FRBRExpression { |b|
                b.FRBRthis(value: "#{EXPRESSION_URI}/main")
                b.FRBRuri(value: EXPRESSION_URI)
                b.FRBRdate(date: '1980-01-01', name: 'Generation')
                b.FRBRauthor(href: '#council')
                b.FRBRlanguage(language: 'eng')
              }
              b.FRBRManifestation { |b|
                b.FRBRthis(value: "#{MANIFESTATION_URI}/main")
                b.FRBRuri(value: MANIFESTATION_URI)
                b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
                b.FRBRauthor(href: '#slaw')
              }
            }
          end

          def write_preface(b)
            preface.to_xml(b) if preface.respond_to? :to_xml
          end

          def write_preamble(b)
            preamble.to_xml(b) if preamble.respond_to? :to_xml
          end

          def write_body(b)
            body.to_xml(b)
          end

          def write_schedules(b)
            if schedules.text_value != ""
              schedules.to_xml(b)
            end
          end
        end

        class Preface < Treetop::Runtime::SyntaxNode
          def to_xml(b, *args)
            if text_value != ""
              b.preface { |b|
                statements.elements.each { |element|
                  for e in element.elements
                    e.to_xml(b, "") if e.is_a? Slaw::Grammars::Inlines::NakedStatement
                  end
                }
              }
            end
          end
        end

        class Preamble < Treetop::Runtime::SyntaxNode
          def to_xml(b, *args)
            if text_value != ""
              b.preamble { |b|
                statements.elements.each { |e|
                  e.to_xml(b, "")
                }
              }
            end
          end
        end

        class Part < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, *args)
            id = "part-#{num}"

            # include a chapter number in the id if our parent has one
            if parent and parent.parent.is_a?(Chapter) and parent.parent.num
              id = "chapter-#{parent.parent.num}.#{id}"
            end

            b.part(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '.', i) }
            }
          end
        end

        class GenericHeading < Treetop::Runtime::SyntaxNode
          def num
            prefix.alphanums.text_value
          end

          def title
            if heading.text_value and heading.respond_to? :content
              heading.content.text_value.strip
            end
          end

          def to_xml(b)
            b.num(num)
            b.heading(title) if title
          end
        end

        class Division < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, *args)
            id = "division-#{num}"

            b.division(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '.', i) }
            }
          end
        end

        class Subdivision < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, *args)
            id = "subdivision-#{num}"

            b.subdivision(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '.', i) }
            }
          end
        end

        class Chapter < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, *args)
            id = "chapter-#{num}"

            # TODO: do this for the oddzial and zial
            # include a part number in the id if our parent has one
            if parent and parent.parent.is_a?(Part) and parent.parent.num
              id = "part-#{parent.parent.num}.#{id}"
            end

            b.chapter(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '.', i) }
            }
          end
        end

        class Article < Treetop::Runtime::SyntaxNode
          def num
            article_prefix.number_letter.text_value
          end

          def to_xml(b, *args)
            id = "article-#{num}"
            idprefix = "#{id}."

            b.article(id: id) { |b|
              b.num("#{num}.")

              if !intro.empty?
                if not children.empty?
                  b.intro { |b| intro.to_xml(b, idprefix) }
                else
                  b.content { |b| intro.to_xml(b, idprefix) }
                end
              elsif children.empty?
                b.content { |b| b.p }
              end

              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Section < Treetop::Runtime::SyntaxNode
          def num
            section_prefix.alphanums.text_value
          end

          def to_xml(b, *args)
            id = "section-#{num}"
            idprefix = "#{id}."

            b.section(id: id) { |b|
              b.num("#{num}.")

              if !intro.empty?
                if not children.empty?
                  b.intro { |b| intro.to_xml(b, idprefix) }
                else
                  b.content { |b| intro.to_xml(b, idprefix) }
                end
              elsif children.empty?
                b.content { |b| b.p }
              end

              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Paragraph < Treetop::Runtime::SyntaxNode
          def num
            paragraph_prefix.number_letter.text_value
          end

          def to_xml(b, idprefix='', *args)
            id = "#{idprefix}paragraph-#{num}"
            idprefix = id + "."

            b.paragraph(id: id) { |b|
              b.num(paragraph_prefix.text_value)

              if !intro.empty?
                if not children.empty?
                  b.intro { |b| intro.to_xml(b, idprefix) }
                else
                  b.content { |b| intro.to_xml(b, idprefix) }
                end
              elsif children.empty?
                b.content { |b| b.p }
              end

              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Point < Treetop::Runtime::SyntaxNode
          def num
            point_prefix.number_letter.text_value
          end

          def to_xml(b, idprefix='', i)
            id = "#{idprefix}point-#{num}"
            idprefix = id + "."

            b.point(id: id) { |b|
              b.num(point_prefix.text_value)

              if !intro.empty?
                if not children.empty?
                  b.intro { |b| intro.to_xml(b, idprefix) }
                else
                  b.content { |b| intro.to_xml(b, idprefix) }
                end
              elsif children.empty?
                b.content { |b| b.p }
              end

              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Litera < Treetop::Runtime::SyntaxNode
          def num
            litera_prefix.letters.text_value
          end

          def to_xml(b, idprefix='', i)
            id = "#{idprefix}list-#{num}"
            idprefix = id + "."

            b.list(id: id) { |b|
              b.num(litera_prefix.text_value)

              if !intro.empty?
                if not children.empty?
                  b.intro { |b| intro.to_xml(b, idprefix) }
                else
                  b.content { |b| intro.to_xml(b, idprefix) }
                end
              elsif children.empty?
                b.content { |b| b.p }
              end

              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class BlockParagraph < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix='', i=0)
            id = "#{idprefix}paragraph-0"
            idprefix = id + "."

            b.paragraph(id: id) { |b|
              b.content { |b|
                elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
              }
            }
          end
        end

        class Indents < Treetop::Runtime::SyntaxNode
          # Render a list of indent items.
          def to_xml(b, idprefix, i=0)
            id = idprefix + "list-#{i}"
            idprefix = id + '.'

            b.list(id: id) { |b|
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class IndentItem < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            id = idprefix + "indent-#{i}"
            idprefix = id + '.'

            b.indent(id: id) { |b|
              b.content { |b|
                if not item_content.empty?
                  item_content.to_xml(b, idprefix)
                else
                  b.p
                end
              }
            }
          end
        end

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
              schedule_title.title.text_value
            elsif num
              "Schedule #{num}"
            else
              "Schedule"
            end
          end

          def heading
            if schedule_title.heading.respond_to? :content
              schedule_title.heading.content.text_value
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
                      b.FRBRthis(value: "#{Act::WORK_URI}/#{component}")
                      b.FRBRuri(value: Act::WORK_URI)
                      b.FRBRalias(value: self.alias)
                      b.FRBRdate(date: '1980-01-01', name: 'Generation')
                      b.FRBRauthor(href: '#council')
                      b.FRBRcountry(value: 'za')
                    }
                    b.FRBRExpression { |b|
                      b.FRBRthis(value: "#{Act::EXPRESSION_URI}/#{component}")
                      b.FRBRuri(value: Act::EXPRESSION_URI)
                      b.FRBRdate(date: '1980-01-01', name: 'Generation')
                      b.FRBRauthor(href: '#council')
                      b.FRBRlanguage(language: 'eng')
                    }
                    b.FRBRManifestation { |b|
                      b.FRBRthis(value: "#{Act::MANIFESTATION_URI}/#{component}")
                      b.FRBRuri(value: Act::MANIFESTATION_URI)
                      b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
                      b.FRBRauthor(href: '#slaw')
                    }
                  }
                }

                b.mainBody { |b| 
                  idprefix = "#{id}."

                  # there is no good AKN hierarchy container for schedules, so we
                  # just use article because we don't use it anywhere else.
                  b.article(id: id) { |b|
                    b.heading(heading) if heading
                    body.children.elements.each_with_index { |e| e.to_xml(b, idprefix, i) } if body.is_a? Body
                  }
                }
              }
            }
          end
        end

        class ScheduleStatement < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix)
            b.p { |b| clauses.to_xml(b, idprefix) } if clauses
          end
        end
      end
    end
  end
end
