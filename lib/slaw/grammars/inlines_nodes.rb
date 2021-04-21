module Slaw
  module Grammars
    module Inlines
      class NakedStatement < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          b.p { |b| inline_items.to_xml(b, idprefix) } unless inline_items.empty?
        end
      end

      class InlineItems < Treetop::Runtime::SyntaxNode
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
          if text_value.start_with? '\\'
            # handle escaped characters: \a -> a
            b.text(text_value[1..])
          else
            b.text(text_value)
          end
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

      class Superscript < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.sup { |b|
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
          }
        end
      end

      class Subscript < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.sub { |b|
            for e in content.elements
              e.inline_item.to_xml(b, idprefix)
            end
          }
        end
      end

    end
  end
end
