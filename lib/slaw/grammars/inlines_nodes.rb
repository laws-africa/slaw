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
            if e.respond_to? :to_xml
              e.to_xml(b, idprefix)
            else
              b.text(e.text_value)
            end
          end
        end
      end

      class Remark < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.remark(status: 'editorial') do |b|
            b.text('[')
            for e in content.elements
              if e.respond_to? :to_xml
                e.to_xml(b, idprefix)
              else
                b.text(e.text_value)
              end
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

      class Ref < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix)
          b.ref(content.text_value, href: href.text_value)
        end
      end

    end
  end
end
