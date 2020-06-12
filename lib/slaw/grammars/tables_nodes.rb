module Slaw
  module Grammars
    module Tables
      class Table < Treetop::Runtime::SyntaxNode
        def to_xml(b, idprefix, i=0)
          cnt = Slaw::Grammars::Counters.counters[idprefix]['table'] += 1

          b.table(eId: "#{idprefix}table_#{cnt}") { |b|
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
          tag = table_cell_start.th? ? 'th' : 'td'

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
          inline_items.to_xml(b) unless inline_items.empty?

          # add trailing newlines.
          #   for the first line, eat whitespace at the start
          #   for the last line, eat whitespace at the end
          if not tail and (i > 0 or not inline_items.empty?)
            eol.text_value.count("\n").times { b.eol }
          end
        end
      end
    end
  end
end
