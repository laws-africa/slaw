require 'wikicloth'

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

          b.subsection(id: id) { |b|
            b.num(num)
            b.content { |b|
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
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
            for e2 in e.elements
              if e2.respond_to? :to_xml
                e2.to_xml(b, idprefix)
              else
                b << e2.text_value
              end
            end
          end
        end
      end

      class Remark < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.remark('[' + content.text_value + ']', status: 'editorial')
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

        def content
          # TODO this really seems a bit odd
          item_content.content.text_value if respond_to? :item_content and item_content.respond_to? :content
        end

        def to_xml(b, idprefix)
          b.item(id: idprefix + num.gsub(/[()]/, '')) { |b|
            b.num(num)
            b.p(content) if content
          }
        end
      end

      class Table < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          # parse the table using wikicloth
          html = WikiCloth::Parser.new({data: self.text_value}).to_html

          # we need to strip any surrounding p tags and add
          # an id to the table
          html = Nokogiri::HTML(html)
          table = html.css("table").first
          table['id'] = "#{idprefix}table#{i}"

          # wrap td and th content in p tags
          table.css("td, th").each do |cell|
            p = Nokogiri::XML::Node.new("p", html)
            p.children = cell.children
            p.parent = cell

            # replace newlines with <eol>
            p.search("text()").each do |text|
              lines = text.content.strip.split(/\n+/)
              text.content = lines.shift

              for line in lines
                eol = text.add_next_sibling(Nokogiri::XML::Node.new("eol", html))
                text = eol.add_next_sibling(Nokogiri::XML::Text.new(line, html))
              end
            end
          end

          table.xpath('//text()[1]').each{ |t|      t.content = t.content.lstrip }
          table.xpath('//text()[last()]').each{ |t| t.content = t.content.rstrip }

          b.parent << table
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
