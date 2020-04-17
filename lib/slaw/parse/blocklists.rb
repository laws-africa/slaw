module Slaw
  module Parse
    module Blocklists

      def self.adjust_blocklists(doc)
        nest_blocklists(doc)
        fix_intros(doc)
      end

      # Correctly re-nest nested block lists that are tagged with the "renest" attribute.
      #
      # We do this by identifying the numbering format of each item in the list
      # and comparing it with the surrounding elements. When the numbering
      # format changes, we start a new nested list.
      #
      # We make sure to handle special cases such as `(i)` coming between
      # `(h)` and `(j)` versus being at the start of a `(i), (ii), (iii)`
      # list.
      #
      #     (a)
      #     (b)
      #     (i)
      #     (ii)
      #     (aa)
      #     (bb)
      #     (c)
      #     (d)
      #
      # becomes
      #
      #     (a)
      #     (b)
      #       (i)
      #       (ii)
      #         (aa)
      #         (bb)
      #     (c)
      #     (d)
      #
      # @param doc [Nokogiri::XML::Document] the document
      def self.nest_blocklists(doc)
        doc.xpath('//a:blockList[@renest]', a: Slaw.akn_namespace).each do |blocklist|
          blocklist.remove_attribute('renest')
          items = blocklist.xpath('a:item', a: Slaw.akn_namespace)
          nest_blocklist_items(items.to_a, guess_number_format(items.first), nil, nil) unless items.empty?
        end
      end

      # New blocklist nesting, starting with +item+ as its
      # first element. 
      def self.nest_blocklist_items(items, our_number_format, list, prev)
        return if items.empty?
        item = items.shift

        sublist_count = 0
        number_format = our_number_format

        while item and item.name == 'item'
          number_format = guess_number_format(item, number_format)
          break unless number_format

          # (aa) after (z) is same numbering type, pretend we've always
          # been this format
          if item.num == "(aa)" and item.previous_element and item.previous_element.num == "(z)"
            our_number_format = number_format
          end

          if number_format != our_number_format
            # new sublist, or back to the old list?
            if number_format < our_number_format
              # back to the old list
              items.unshift(item)
              break
            else
              # new sublist.
              #
              # The blockList is inserted as a child of the sibling just before
              # +item+, and that sibling's content is moved into the
              # +listIntroduction+ of the new list.
              sublist = item.document.create_element('blockList', id: prev['id'] + ".list#{sublist_count}")
              sublist_count += 1

              # list intro
              num = prev.at_xpath('a:num', a: Slaw.akn_namespace)
              if intro = num.next_element
                intro.name = 'listIntroduction'
                sublist << intro
              end

              # make +item+ the first in this list
              item['id'] = sublist['id'] + ".#{item.num.gsub(/[()]/, '')}"
              sublist << item

              # insert this list as a child of the previous item
              prev << sublist

              # now keep walking item's (old) siblings
              # and pull in those elements that match our numbering
              # scheme
              nest_blocklist_items(items, number_format, sublist, item)
            end
          else
            # same number format

            # if this num is (i), we're numbering in :i, this isn't the first
            # element in this list, then assume we're following (h) with (i)
            if number_format.type == :i && item.num == "(i)" && prev
              items.unshift(item)
              break
            else
              # keep it with this list
              if list
                list << item
                item['id'] = list['id'] + ".#{item.num.gsub(/[()]/, '')}"
              end
            end
          end

          prev = item
          item = items.shift
        end
      end

      def self.guess_number_format(item, prev_format=nil)
        return nil unless item.num

        prev = item.previous_element
        nxt  = item.next_element

        case item.num
        when "(i)"
          # Special case to detect difference between:
          #
          # (h) foo
          # (i) bar
          # (j) baz
          #
          # and
          #
          # (h) foo
          #   (i)  bar
          #   (ii) baz
          #
          # (i) is NOT a sublist if:
          #   - there was a previous item (h), and
          #     - there is not a next item, or
          #     - the next item is something other than (ii)
          if prev and prev.num =~ /^\(h/ and (!nxt or nxt.num != "(ii)")
            NumberingFormat.a
          else
            NumberingFormat.i
          end
        when "(u)", "(v)", "(x)"
          prev_format
        when /^\([ivx]+/
          NumberingFormat.i
        when /^\([IVX]+/
          NumberingFormat.I
        when /^\([a-z]{2}/
          NumberingFormat.aa
        when /^\([A-Z]{2}/
          NumberingFormat.AA
        when /^\([a-z]+/
          NumberingFormat.a
        when /^\([A-Z]+/
          NumberingFormat.A
        when /^\d+(\.\d+)+$/
          NumberingFormat.new(:'i.i', item.num.count('.'))
        else
          NumberingFormat.unknown
        end
      end

      # Change p tags preceding a blocklist into listIntroductions within the blocklist
      def self.fix_intros(doc)
        doc.xpath('//a:blockList', a: Slaw.akn_namespace).each do |blocklist|
          prev = blocklist.previous
          if prev and prev.name == 'p'
            prev.name = 'listIntroduction'
            blocklist.prepend_child(prev)
          end
        end
      end

      class NumberingFormat
        include Comparable

        attr_accessor :type, :ordinal

        def initialize(type, ordinal)
          @type = type
          @ordinal = ordinal
        end

        def eql?(other)
          self.ordinal == other.ordinal
        end

        def <=>(other)
          self.ordinal <=> other.ordinal
        end

        def to_s
          @type.to_s
        end

        @@a = NumberingFormat.new(:a, 0)
        @@A = NumberingFormat.new(:a, 1)
        @@i = NumberingFormat.new(:i, 2)
        @@I = NumberingFormat.new(:I, 3)
        @@aa = NumberingFormat.new(:aa, 4)
        @@AA = NumberingFormat.new(:AA, 5)
        @@unknown = NumberingFormat.new(:unknown, 9)

        def self.a; @@a; end
        def self.A; @@A; end
        def self.i; @@i; end
        def self.I; @@I; end
        def self.aa; @@aa; end
        def self.AA; @@AA; end
        def self.unknown; @@unknown; end
      end
    end
  end
end
