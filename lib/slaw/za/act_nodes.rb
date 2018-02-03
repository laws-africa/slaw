module Slaw
  module ZA
    module Act
      class Act < Treetop::Runtime::SyntaxNode
        FRBR_URI = '/za/act/1980/01'
        WORK_URI = FRBR_URI
        EXPRESSION_URI = "#{FRBR_URI}/eng@"
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

      class Body < Treetop::Runtime::SyntaxNode
        def to_xml(b)
          b.body { |b|
            children.elements.each_with_index { |e, i| e.to_xml(b, '', i) }
          }
        end
      end

      class GroupNode < Treetop::Runtime::SyntaxNode
        def to_xml(b, *args)
          children.elements.each { |e| e.to_xml(b, *args) }
        end
      end

      class Preface < Treetop::Runtime::SyntaxNode
        def to_xml(b, *args)
          if text_value != ""
            b.preface { |b|
              statements.elements.each { |element|
                for e in element.elements
                  e.to_xml(b, "") if e.is_a? NakedStatement
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

      class PartHeading < Treetop::Runtime::SyntaxNode
        def num
          part_heading_prefix.alphanums.text_value
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

      class Chapter < Treetop::Runtime::SyntaxNode
        def num
          heading.num
        end

        def to_xml(b, *args)
          id = "chapter-#{num}"

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

      class ChapterHeading < Treetop::Runtime::SyntaxNode
        def num
          chapter_heading_prefix.alphanums.text_value
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

      class Section < Treetop::Runtime::SyntaxNode
        def num
          section_title.num
        end

        def title
          section_title.title
        end

        def to_xml(b, *args)
          id = "section-#{num}"
          b.section(id: id) { |b|
            b.num("#{num}.")
            b.heading(title)

            idprefix = "#{id}."

            children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
          }
        end
      end

      class SectionTitleType1 < Treetop::Runtime::SyntaxNode
        # a section title of the form:
        #
        # Definitions
        # 1. In this act...

        def num
          section_title_prefix.number_letter.text_value
        end

        def title
          content.text_value
        end
      end

      class SectionTitleType2 < Treetop::Runtime::SyntaxNode
        # a section title of the form:
        #
        # 1. Definitions
        # In this act...
        #
        # In this format, the title is optional and the section content may
        # start where we think the title is.

        def num
          section_title_prefix.number_letter.text_value
        end

        def title
          section_title.empty? ? "" : section_title.content.text_value
        end
      end

      class BlockParagraph < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix='', i=0)
          id = "#{idprefix}paragraph-0"
          idprefix = "#{id}."

          b.paragraph(id: id) { |b|
            b.content { |b|
              elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          }
        end
      end

      class Subsection < Treetop::Runtime::SyntaxNode
        def num
          subsection_prefix.num.text_value
        end

        def to_xml(b, idprefix, i)
          id = idprefix + num.gsub(/[()]/, '')
          idprefix = id + "."

          kids = children.elements
          kids = [first_child] + kids if first_child and !first_child.empty?

          b.subsection(id: id) { |b|
            b.num(num)
            b.content { |b|
              if kids.empty?
                # schema requires a non-empty content element
                b.p
              else
                kids.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
              end
            }
          }
        end
      end

      class NakedStatement < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          b.p { |b| clauses.to_xml(b, idprefix) } if clauses
        end

        def content
          clauses
        end
      end

      class Clauses < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix=nil)
          for e in elements
            if e.respond_to? :to_xml
              e.to_xml(b, idprefix)
            else
              b << e.text_value
            end
          end
        end
      end

      class Remark < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.remark(status: 'editorial') do |b|
            b << '['
            for e in content.elements
              if e.respond_to? :to_xml
                e.to_xml(b, idprefix)
              else
                b << e.text_value
              end
            end
            b << ']'
          end
        end
      end

      class Image < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          attrs = {src: href.text_value}
          attrs[:alt] = content.text_value unless content.text_value.empty?
          b.img(attrs)
        end
      end

      class Ref < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.ref(content.text_value, href: href.text_value)
        end
      end

      class Blocklist < Treetop::Runtime::SyntaxNode
        # Render a block list to xml. If a block is given,
        # yield to it a builder to insert a listIntroduction node
        def to_xml(b, idprefix, i=0, &block)
          id = idprefix + "list#{i}"
          idprefix = id + '.'

          b.blockList(id: id) { |b|
            b.listIntroduction { |b| yield b } if block_given?

            elements.each { |e| e.to_xml(b, idprefix) }
          }
        end
      end

      class BlocklistItem < Treetop::Runtime::SyntaxNode
        def num
          blocklist_item_prefix.text_value
        end

        def to_xml(b, idprefix)
          b.item(id: idprefix + num.gsub(/[()]/, '')) { |b|
            b.num(num)
            b.p { |b|
              item_content.clauses.to_xml(b, idprefix) if respond_to? :item_content and item_content.respond_to? :clauses
            }
          }
        end
      end

      class Table < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          b.table(id: "#{idprefix}table#{i}") { |b|
            # we'll gather cells into this row list
            rows = []
            cells = []

            for child in table_body.elements
              if child.is_a? TableCell
                # cell
                cells << child
              else
                # new row marker
                rows << cells unless cells.empty?
                cells = []
              end
            end
            rows << cells unless cells.empty?

            for row in rows
              b.tr { |tr|
                for cell in row
                  cell.to_xml(tr, "")
                end
              }
            end
          }
        end
      end

      class TableCell < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          tag = text_value[0] == '!' ? 'th' : 'td'

          attrs = {}
          if not attribs.empty?
            for item in attribs.attribs.elements
              # key=value (strip quotes around value)
              attrs[item.name.text_value.strip] = item.value.text_value[1..-2]
            end
          end

          b.send(tag.to_sym, attrs) { |b|
            b.p { |b|
              # first line, and the rest
              lines = [content.line] + content.elements.last.elements.map(&:line)

              lines.each_with_index do |line, i|
                line.to_xml(b, i, i == lines.length-1)
              end
            }
          }
        end
      end

      class TableLine < Treetop::Runtime::SyntaxNode
        # line of table content
        def to_xml(b, i, tail)
          clauses.to_xml(b) unless clauses.empty?

          # add trailing newlines.
          #   for the first line, eat whitespace at the start
          #   for the last line, eat whitespace at the end
          if not tail and (i > 0 or not clauses.empty?)
            eol.text_value.count("\n").times { b.eol }
          end
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
