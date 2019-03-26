module Slaw
  module Grammars
    module Inlines
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
            e.to_xml(b, idprefix)
          end
        end
      end

      class Remark < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.remark(status: 'editorial') do |b|
            b.text('[')
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
            b.text(']')
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

      class InlineItem < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.text(text_value)
        end
      end

      class Ref < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.ref(href: href.text_value) { |b|
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
          }
        end
      end

      class Bold < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.b { |b|
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
          }
        end
      end

      class Italics < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.i { |b|
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
          }
        end
      end

    end
  end
end
