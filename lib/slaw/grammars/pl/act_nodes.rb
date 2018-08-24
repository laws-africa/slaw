require 'slaw/grammars/core_nodes'

module Slaw
  module Grammars
    module PL
      module Act



        #############################################################
        # MISC NOT CORRESPONDING TO act.treetop - E.G. SUPERCLASSES #
        #############################################################
        
        # Note that b/c order of declaration in Ruby matters, these must go at the beginning.

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

        class BlockWithIntroAndChildren < Treetop::Runtime::SyntaxNode
          def intro_node
            if intro.elements.length >= 1
              el = intro.elements[0]

              if el.respond_to? :intro_inline
                el.intro_inline
              elsif el.respond_to? :intro_block
                el.intro_block
              end
            end
          end

          def intro_and_children_xml(b, idprefix)
            if intro_node and !intro_node.empty?
              if not children.empty?
                b.intro { |b| intro_node.to_xml(b, idprefix) }
              else
                b.content { |b| intro_node.to_xml(b, idprefix) }
              end
            elsif children.empty?
              b.content { |b| b.p }
            end

            children.elements.each_with_index { |e, i|
              e.to_xml(b, idprefix, i)
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



        ####################
        # MAJOR CONTAINERS #
        ####################        

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
                # Define various Poland-specific distinctions to augment AKN-provided law
                # hierarchy units. We put references to these in "refersTo" attribute.
                # 
                # For example, AKN suggest representing both the Polish "punkt" (= point) and
                # "litera" (= letter) as <point>. To clearly preserve the distinction
                # between them, we put them in AKN as <point refersTo="point_unit"> and
                # <point refersTo="letter_unit">.
                #
                # See https://groups.google.com/forum/?fromgroups=#!topic/akomantoso-xml/7sW5HtZbPcs
                # for discussion.
                b.TLCConcept(id: "statute", href: '/akn/ontology/concept/pl/statute',
                  showAs: "statute", eId: "statute")
                b.TLCConcept(id: "ordinance", href: '/akn/ontology/concept/pl/ordinance',
                  showAs: "ordinance", eId: "ordinance")
                b.TLCConcept(id: "noncode_level1_unit", 
                  href: '/akn/ontology/concept/pl/noncode_level1_unit',
                  showAs: "noncode_level1_unit", eId: "noncode_level1_unit")
                b.TLCConcept(id: "code_level1_unit", 
                  href: '/akn/ontology/concept/pl/code_level1_unit',
                  showAs: "code_level1_unit", eId: "code_level1_unit")
                b.TLCConcept(id: "point_unit", href: '/akn/ontology/concept/pl/point_unit',
                  showAs: "point_unit", eId: "point_unit")
                b.TLCConcept(id: "letter_unit", href: '/akn/ontology/concept/pl/letter_unit',
                  showAs: "letter_unit", eId: "letter_unit")
                b.TLCConcept(id: "wrap_up_for_points",
                  href: '/akn/ontology/concept/pl/wrap_up_for_points',
                  showAs: "wrap_up_for_points", eId: "wrap_up_for_points")
                b.TLCConcept(id: "wrap_up_for_letters",
                  href: '/akn/ontology/concept/pl/wrap_up_for_letters',
                  showAs: "wrap_up_for_letters", eId: "wrap_up_for_letters")
                b.TLCConcept(id: "single_tiret", href: '/akn/ontology/concept/pl/single_tiret',
                  showAs: "single_tiret", eId: "single_tiret")
                b.TLCConcept(id: "double_tiret", href: '/akn/ontology/concept/pl/double_tiret',
                  showAs: "double_tiret", eId: "double_tiret")
                b.TLCConcept(id: "triple_tiret", href: '/akn/ontology/concept/pl/triple_tiret',
                  showAs: "triple_tiret", eId: "triple_tiret")
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
              b.preface { |b|
                b.docNumber { |b|
                  signature.elements.each { |element|
                    b << element.text_value
                  }
                }
                b.docType { |b|
                  if act_type.text_value.delete(" ") == "USTAWA"
                    b << "statute"
                  end
                  if act_type.text_value.delete(" ") == "ROZPORZĄDZENIE"
                    b << "ordinance"
                  end
                }
                b.docDate { |b|
                  act_date.elements.each { |element|
                    b << element.text_value
                  }
                }
                b.docTitle { |b|
                  act_title.statements.elements.each { |element|
                    element.to_xml(b, "")
                  }
                }
              }
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

        class Title < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end
  
          def to_xml(b, *args)
            id = "title-#{num}"
            idprefix = "#{id}."
  
            b.title(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Division < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, idprefix = '', *args)
            id = "#{idprefix}division-#{num}"
            idprefix = "#{id}."

            b.division(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Subdivision < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, idprefix='', *args)
            id = "#{idprefix}subdivision-#{num}"
            idprefix = "#{id}."

            b.subdivision(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class Chapter < Treetop::Runtime::SyntaxNode
          def num
            heading.num
          end

          def to_xml(b, idprefix='', *args)
            id = "#{idprefix}chapter-#{num}"
            idprefix = "#{id}."

            # TODO: do this for the oddzial and zial
            # include a part number in the id if our parent has one
            if parent and parent.parent.is_a?(Part) and parent.parent.num
              id = "part-#{parent.parent.num}.#{id}"
            end

            b.chapter(id: id) { |b|
              heading.to_xml(b)
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class StatuteLevel0 < BlockWithIntroAndChildren
          def num
            (statute_level0_unit_prefix.number_letter.text_value +
              (statute_level0_unit_prefix.superscript.respond_to?('number_letter') ?
                ("^" + statute_level0_unit_prefix.superscript.number_letter.text_value) : ""))
          end

          def to_xml(b, *args)
            id = "section-#{num}"
            idprefix = "#{id}."

            b.section(id: id, refersTo: "statute") { |b|
              b.num("#{num}")
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        class OrdinanceLevel0 < BlockWithIntroAndChildren
          def num
            (ordinance_level0_unit_prefix.number_letter.text_value +
              (ordinance_level0_unit_prefix.superscript.respond_to?('number_letter') ?
                ("^" + ordinance_level0_unit_prefix.superscript.number_letter.text_value) : ""))
          end

          def to_xml(b, *args)
            id = "section-#{num}"
            idprefix = "#{id}."

            b.section(id: id, refersTo: "ordinance") { |b|
              b.num("#{num}")
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        # TODO: Add superscript possibility for units lower than level 0.

        class NoncodeLevel1 < BlockWithIntroAndChildren
          def num
            noncode_level1_unit_prefix.number_letter.text_value
          end

          def to_xml(b, idprefix='', *args)
            id = "#{idprefix}subsection-#{num}"
            idprefix = "#{id}."

            b.subsection(id: id, refersTo: "noncode_level1_unit") { |b|
              b.num("#{num}")
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        class CodeLevel1 < BlockWithIntroAndChildren
          def num
            code_level1_unit_prefix.number_letter.text_value
          end
  
          def to_xml(b, idprefix='', *args)
            id = "#{idprefix}subsection-#{num}"
            idprefix = "#{id}."
  
            b.subsection(id: id, refersTo: "code_level1_unit") { |b|
              b.num("#{num}")
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        class Point < BlockWithIntroAndChildren
          def num
            point_prefix.number_letter.text_value
          end

          def to_xml(b, idprefix='', i)
            id = "#{idprefix}point-#{num}"
            idprefix = id + "."

            b.point(id: id, refersTo: "point_unit") { |b|
              b.num(point_prefix.text_value)
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        class LetterUnit < BlockWithIntroAndChildren
          def num
            letter_prefix.letters.text_value
          end

          def to_xml(b, idprefix='', i)
            id = "#{idprefix}point-#{num}"
            idprefix = id + "."

            b.point(id: id, refersTo: "letter_unit") { |b|
              b.num(letter_prefix.text_value)
              intro_and_children_xml(b, idprefix)
            }
          end
        end

        class Tiret < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            id = idprefix + "list-#{i}"
            idprefix = id + '.'

            b.list(id: id) { |b|
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class DoubleTiret < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            id = idprefix + "list-#{i}"
            idprefix = id + '.'
  
            b.list(id: id) { |b|
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end

        class TripleTiret < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i=0)
            id = idprefix + "list-#{i}"
            idprefix = id + '.'
  
            b.list(id: id) { |b|
              children.elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
            }
          end
        end



        #####################
        # HELPER CONTAINERS #
        #####################

        class DashedWrapUpForPoints < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            b.wrapUp(refersTo: 'wrap_up_for_points') { |b|
              b.p() { |b|
                 dashed_wrapup_content.elements.each { |e| b << e.text_value }
              }
            }
          end
        end
        
        class DashedWrapUpForLetters < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            b.wrapUp(refersTo: 'wrap_up_for_letters') { |b|
              b.p() { |b|
                 dashed_wrapup_content.elements.each { |e| b << e.text_value }
              }
            }
          end
        end

        class TiretItem < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            id = idprefix + "indent-#{i}"
            idprefix = id + '.'

            b.indent(id: id, refersTo: "single_tiret") { |b|
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

        class DoubleTiretItem < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            id = idprefix + "indent-#{i}"
            idprefix = id + '.'
  
            b.indent(id: id, refersTo: "double_tiret") { |b|
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
  
        class TripleTiretItem < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix, i)
            id = idprefix + "indent-#{i}"
            idprefix = id + '.'
  
            b.indent(id: id, refersTo: "triple_tiret") { |b|
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



        #######################################
        # BLOCKS OF CONTENT INSIDE CONTAINERS #
        #######################################
        
        class BlockParagraph < Treetop::Runtime::SyntaxNode
          def to_xml(b, idprefix='', i=0)
            id = "#{idprefix}subparagraph-0"
            idprefix = id + "."
  
            b.subparagraph(id: id) { |b|
              b.content { |b|
                elements.each_with_index { |e, i| e.to_xml(b, idprefix, i) }
              }
            }
          end
        end



      end
    end
  end
end
