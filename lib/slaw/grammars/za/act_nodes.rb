require 'slaw/grammars/core_nodes'
require 'slaw/grammars/counters'

module Slaw
  module Grammars
    module ZA
      module Act
        class Act < Treetop::Runtime::SyntaxNode
          FRBR_URI = '/za/act/1980/01'
          WORK_URI = FRBR_URI
          EXPRESSION_URI = "#{FRBR_URI}/eng@"
          MANIFESTATION_URI = EXPRESSION_URI

          def to_xml(b, idprefix=nil, i=0)
            b.act(contains: 'originalVersion', name: 'act') { |b|
              write_meta(b)
              write_preface(b)
              write_preamble(b)
              write_body(b)
              write_schedules(b)
            }
          end

          def write_meta(b)
            b.meta { |b|
              write_identification(b)

              b.references(source: "#this") {
                b.TLCOrganization(eId: 'slaw', href: 'https://github.com/longhotsummer/slaw', showAs: "Slaw")
                b.TLCOrganization(eId: 'council', href: '/ontology/organization/za/council', showAs: "Council")
              }
            }
          end

          def write_identification(b)
            b.identification(source: "#slaw") { |b|
              # use stub values so that we can generate a validating document
              b.FRBRWork { |b|
                b.FRBRthis(value: "#{WORK_URI}/main")
                b.FRBRuri(value: WORK_URI)
                b.FRBRalias(value: 'Short Title', name: 'title')
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
            stmts = statements.elements
            if !stmts.empty?
              b.preface { |b|
                stmts.each { |element|
                  for e in element.elements
                    e.to_xml(b, "") if e.respond_to? :to_xml
                  end
                }
              }
            end
          end
        end

        class PrefaceStatement < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            if longtitle
              longtitle.to_xml(b, idprefix)
            else
              b.p { |b| inline_items.to_xml(b, idprefix) }
            end
          end

          def longtitle
            self.content if self.content.is_a? LongTitle
          end

          def inline_items
            content.inline_items if content.respond_to? :inline_items
          end
        end

        class LongTitle < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            b.longTitle { |b|
              b.p { |b| inline_items.to_xml(b, idprefix) }
            }
          end
        end

        class Preamble < Treetop::Runtime::SyntaxNode
          def to_xml(b, *args)
            stmts = statements.elements
            if !stmts.empty?
              b.preamble { |b|
                stmts.each { |e|
                  e.preamble_statement.to_xml(b, "preamble__")
                }
              }
            end
          end
        end

        class Part < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, id_prefix='', *args)
            id = id_prefix + "part_#{Slaw::Grammars::Counters.clean(num)}"

            b.part(eId: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '__', i) }
            }
          end
        end

        class PartHeading < Treetop::Runtime::SyntaxNode
          def num
            part_heading_prefix.alphanums.text_value
          end

          def to_xml(b)
            b.num(num)
            if heading.respond_to? :inline_items
              b.heading { |b|
                heading.inline_items.to_xml(b)
              }
            end
          end
        end

        class Subpart < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, id_prefix='', *args)
            num = self.num
            if num.empty?
              num = Slaw::Grammars::Counters.counters[id_prefix]['subpart'] += 1
            else
              num = Slaw::Grammars::Counters.clean(num)
            end

            id = id_prefix + "subpart_#{num}"

            b.subpart(eId: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '__', i) }
            }
          end
        end

        class SubpartHeading < Treetop::Runtime::SyntaxNode
          def num
            subpart_heading_prefix.num.text_value.strip()
          end

          def to_xml(b)
            b.num(num) unless self.num.empty?
            if heading.respond_to? :inline_items
              b.heading { |b|
                heading.inline_items.to_xml(b)
              }
            end
          end
        end

        class Chapter < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, id_prefix='', *args)
            id = id_prefix + "chp_#{Slaw::Grammars::Counters.clean(num)}"

            b.chapter(eId: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, id + '__', i) }
            }
          end
        end

        class ChapterHeading < Treetop::Runtime::SyntaxNode
          def num
            chapter_heading_prefix.alphanums.text_value
          end

          def to_xml(b)
            b.num(num)
            if heading.respond_to? :inline_items
              b.heading { |b|
                heading.inline_items.to_xml(b)
              }
            end
          end
        end

        class Section < Treetop::Runtime::SyntaxNode
          def num
            section_title.num
          end

          def to_xml(b, idprefix='', *args)
            id = "sec_#{Slaw::Grammars::Counters.clean(num)}"
            # For historical reasons, we normally ignore the idprefix for sections, assuming
            # them to be unique. However, in an attachment (eg. a schedule), ensure they
            # are correctly prefixed
            # TODO: always include the idprefix
            id = idprefix + id if idprefix.start_with? 'att_'

            b.section(eId: id) { |b|
              section_title.to_xml(b)

              idprefix = "#{id}__"
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

          def to_xml(b, *args)
            b.num("#{num}.")

            if inline_items.text_value
              b.heading { |b|
                inline_items.to_xml(b)
              }
            end
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

          def to_xml(b, *args)
            b.num("#{num}.")

            if section_title.respond_to? :inline_items and section_title.inline_items.text_value
              b.heading { |b|
                section_title.inline_items.to_xml(b)
              }
            else
              b.heading
            end
          end
        end

        class BlockElementsWithInline < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix='')
            b.content { |b|
              kids = [first_child] + children.elements
              kids = kids.select { |k| k and !k.text_value.strip.empty? }

              if kids.empty?
                # schema requires a non-empty content element
                b.p
              else
                kids.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
              end
            }
          end
        end

        class BlockElements < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix='', i=0)
            cnt = Slaw::Grammars::Counters.counters[idprefix]['hcontainer'] += 1
            id = "#{idprefix}hcontainer_#{cnt}"
            idprefix = "#{id}__"

            b.hcontainer(eId: id, name: 'hcontainer') { |b|
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
            id = idprefix + "subsec_" + Slaw::Grammars::Counters.clean(num)
            idprefix = id + "__"

            b.subsection(eId: id) { |b|
              b.num(num)
              block_elements_with_inline.to_xml(b, idprefix)
            }
          end
        end

        class Blocklist < Treetop::Runtime::SyntaxNode
          # Render a block list to xml. If a block is given,
          # yield to it a builder to insert a listIntroduction node
          def to_xml(b, idprefix, i=0, &block)
            cnt = Slaw::Grammars::Counters.counters[idprefix]['list'] += 1
            id = idprefix + "list_#{cnt}"
            idprefix = id + '__'

            b.blockList(eId: id, renest: true) { |b|
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
            b.item(eId: idprefix + "item_" + Slaw::Grammars::Counters.clean(num)) { |b|
              b.num(num)
              b.p { |b|
                item_content.inline_items.to_xml(b, idprefix) if respond_to? :item_content and item_content.respond_to? :inline_items
              }
            }
          end
        end

        class Crossheading < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            cnt = Slaw::Grammars::Counters.counters[idprefix]['crossHeading'] += 1
            id = "#{idprefix}crossHeading_#{cnt}"

            b.crossHeading(eId: id) { |b|
                inline_items.to_xml(b, idprefix)
            }
          end
        end
      end
    end
  end
end
