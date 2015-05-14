require 'wikicloth'

module Slaw
  module ZA
    module Act
      class Act < Treetop::Runtime::SyntaxNode
        FRBR_URI = '/za/act/1980/01'
        WORK_URI = FRBR_URI
        EXPRESSION_URI = "#{FRBR_URI}/eng@"
        MANIFESTATION_URI = EXPRESSION_URI

        def to_xml(b, idprefix)
          b.act(contains: "originalVersion") { |b|
            write_meta(b)
            write_preamble(b)
            write_body(b)
          }
          write_schedules(b)
        end

        def write_meta(b)
          b.meta { |b|
            write_identification(b)

            b.publication(date: '1980-01-01',
                          name: 'Publication Name',
                          number: 'XXXX',
                          showAs: 'Publication Name')

            b.references(source: "#this") {
              b.TLCOrganization(id: 'slaw', href: 'https://github.com/longhotsummer/slaw', showAs: "Slaw")
              b.TLCOrganization(id: 'council', href: '/ontology/organization/za/council', showAs: "Council")
              b.TLCRole(id: 'author', href: '/ontology/role/author', showAs: 'Author')
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
              b.FRBRauthor(href: '#council', as: '#author')
              b.FRBRcountry(value: 'za')
            }
            b.FRBRExpression { |b|
              b.FRBRthis(value: "#{EXPRESSION_URI}/main")
              b.FRBRuri(value: EXPRESSION_URI)
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#council', as: '#author')
              b.FRBRlanguage(language: 'eng')
            }
            b.FRBRManifestation { |b|
              b.FRBRthis(value: "#{MANIFESTATION_URI}/main")
              b.FRBRuri(value: MANIFESTATION_URI)
              b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
              b.FRBRauthor(href: '#slaw', as: '#author')
            }
          }
        end

        def write_preamble(b)
          preamble.to_xml(b)
        end

        def write_body(b)
          b.body { |b|
            chapters.elements.each { |e| e.to_xml(b) }
          }
        end

        def write_schedules(b)
          schedules.to_xml(b)
        end
      end

      class Preamble < Treetop::Runtime::SyntaxNode
        def to_xml(b)
          if text_value != ""
            b.preamble { |b|
              statements.elements.each { |e|
                if not (e.content.text_value =~ /^preamble/i)
                  b.p(e.content.text_value)
                end
              }
            }
          end
        end
      end

      class Part < Treetop::Runtime::SyntaxNode
        def num
          heading.empty? ? nil : heading.num
        end

        def to_xml(b)
          # do we have a part heading?
          if not heading.empty?
            id = "part-#{num}"

            # include a chapter number in the id if our parent has one
            if parent and parent.parent.is_a?(Chapter) and parent.parent.num
              id = "chapter-#{parent.parent.num}.#{id}"
            end

            b.part(id: id) { |b|
              heading.to_xml(b)
              sections.elements.each { |e| e.to_xml(b) }
            }
          else
            # no parts
            sections.elements.each { |e| e.to_xml(b) }
          end
        end
      end

      class PartHeading < Treetop::Runtime::SyntaxNode
        def num
          part_heading_prefix.alphanums.text_value
        end

        def title
          content.text_value
        end

        def to_xml(b)
          b.num(num)
          b.heading(title)
        end
      end

      class Chapter < Treetop::Runtime::SyntaxNode
        def num
          heading.empty? ? nil : heading.num
        end

        def to_xml(b)
          # do we have a chapter heading?
          if not heading.empty?
            id = "chapter-#{num}"

            # include a part number in the id if our parent has one
            if parent and parent.parent.is_a?(Part) and parent.parent.num
              id = "part-#{parent.parent.num}.#{id}"
            end

            b.chapter(id: id) { |b|
              heading.to_xml(b)
              parts.elements.each { |e| e.to_xml(b) }
            }
          else
            # no chapters
            parts.elements.each { |e| e.to_xml(b) }
          end
        end
      end

      class ChapterHeading < Treetop::Runtime::SyntaxNode
        def num
          chapter_heading_prefix.alphanums.text_value
        end

        def title
          if self.respond_to? :heading
            heading.content.text_value
          elsif self.respond_to? :content
            content.text_value
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

        def to_xml(b)
          id = "section-#{num}"
          b.section(id: id) { |b|
            b.num("#{num}.")
            b.heading(title)

            idprefix = "#{id}."

            subsections.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
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

      class Subsection < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          if statement.is_a?(NumberedStatement)
            attribs = {id: idprefix + statement.num.gsub(/[()]/, '')}
          elsif statement.is_a?(Remark)
            statement.to_xml(b)
            return
          else
            attribs = {id: idprefix + "subsection-#{i}"}
          end

          idprefix = attribs[:id] + "."

          b.subsection(attribs) { |b|
            b.num(statement.num) if statement.is_a?(NumberedStatement)
            
            b.content { |b| 
              if blocklist and blocklist.is_a?(Blocklist)
                if statement.content
                  blocklist.to_xml(b, idprefix, i) { |b| b << statement.content.text_value }
                else
                  blocklist.to_xml(b, idprefix, i)
                end
              else
                # raw content
                statement.to_xml(b, idprefix)
              end
            }
          }
        end
      end

      class NumberedStatement < Treetop::Runtime::SyntaxNode
        def num
          numbered_statement_prefix.num.text_value
        end

        def parentheses?
          !numbered_statement_prefix.respond_to? :dotted_number_2
        end

        def content
          if elements[3].text_value == ""
            nil
          else
            elements[3].content
          end
        end

        def to_xml(b, idprefix)
          b.p(content.text_value) if content
        end
      end

      class NakedStatement < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.p(content.text_value) if content
        end
      end

      class Remark < Treetop::Runtime::SyntaxNode
        def to_xml(b)
          b.p { |b| b.remark('[' + content.text_value + ']', status: 'editorial') }
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
        def to_xml(b, idprefix)
          # parse the table using wikicloth
          html = WikiCloth::Parser.new({data: self.text_value}).to_html

          # we need to strip any surrounding p tags and add
          # an id to the table
          html = Nokogiri::HTML(html)
          table = html.css("table").first
          table['id'] = "#{idprefix}table0"

          # wrap td and th content in p tags
          table.css("td, th").each do |cell|
            p = Nokogiri::XML::Node.new("p", html)
            p.children = cell.children
            p.parent = cell
          end

          table.xpath('//text()[1]').each{ |t|      t.content = t.content.lstrip }
          table.xpath('//text()[last()]').each{ |t| t.content = t.content.rstrip }

          b << table.to_html
        end
      end

      class ScheduleContainer < Treetop::Runtime::SyntaxNode
        def to_xml(b)
          return if schedules.elements.empty?

          b.components { |b| 
            schedules.elements.each_with_index { |e, i| 
              b.component(id: "component-#{i+1}") { |b|
                e.to_xml(b, "", i+1)
              }
            }
          }
        end
      end

      class Schedule < Treetop::Runtime::SyntaxNode
        def num
          n = schedule_heading.num.text_value
          return (n && !n.empty?) ? n : nil
        end

        def alias
          if num
            "Schedule #{num}"
          else
            "Schedule"
          end
        end

        def heading
          if schedule_heading.schedule_title.respond_to? :content
            schedule_heading.schedule_title.content.text_value
          else
            nil
          end
        end

        def to_xml(b, idprefix, i=1)
          n = num.nil? ? i : num

          # component name
          comp = "schedule#{n}"
          id = "#{idprefix}schedule-#{n}"

          b.doc(name: "schedule#{n}") { |b|
            b.meta { |b|
              b.identification(source: "#slaw") { |b|
                b.FRBRWork { |b|
                  b.FRBRthis(value: "#{Act::WORK_URI}/#{comp}")
                  b.FRBRuri(value: Act::WORK_URI)
                  b.FRBRalias(value: self.alias)
                  b.FRBRdate(date: '1980-01-01', name: 'Generation')
                  b.FRBRauthor(href: '#council', as: '#author')
                  b.FRBRcountry(value: 'za')
                }
                b.FRBRExpression { |b|
                  b.FRBRthis(value: "#{Act::EXPRESSION_URI}/#{comp}")
                  b.FRBRuri(value: Act::EXPRESSION_URI)
                  b.FRBRdate(date: '1980-01-01', name: 'Generation')
                  b.FRBRauthor(href: '#council', as: '#author')
                  b.FRBRlanguage(language: 'eng')
                }
                b.FRBRManifestation { |b|
                  b.FRBRthis(value: "#{Act::MANIFESTATION_URI}/#{comp}")
                  b.FRBRuri(value: Act::MANIFESTATION_URI)
                  b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
                  b.FRBRauthor(href: '#slaw', as: '#author')
                }
              }
            }

            b.mainBody { |b| 
              # there is no good AKN hierarchy container for schedules, so we
              # just use article because we don't use it anywhere else.
              b.article(id: id) { |b|
                b.heading(heading) if heading
                b.content { |b|
                  statements.elements.each { |e| e.to_xml(b, id + '.') }
                }
              }
            }
          }
        end
      end

      class ScheduleStatement < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.p(content.text_value) if content
        end
      end
    end
  end
end
