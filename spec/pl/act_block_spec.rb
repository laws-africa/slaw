# encoding: UTF-8

require 'slaw'

describe Slaw::ActGenerator do
  subject { Slaw::ActGenerator.new('pl') }

  def parse(rule, s)
    subject.builder.text_to_syntax_tree(s, {root: rule})
  end

  def should_parse(rule, s)
    s << "\n" unless s.end_with?("\n")
    tree = subject.builder.text_to_syntax_tree(s, {root: rule})

    if not tree
      raise Exception.new(subject.failure_reason || "Couldn't match to grammar") if tree.nil?
    else
      # count an assertion
      tree.should_not be_nil
    end
  end

  def to_xml(node, *args)
    b = ::Nokogiri::XML::Builder.new
    node.to_xml(b, *args)
    b.doc.root.to_xml(encoding: 'UTF-8')
  end

  #-------------------------------------------------------------------------------
  # Preface.
  
describe 'ENTITY: Preface' do
  it 'ENTITY VARIATION: Basic.' do
    node = parse :preface, <<EOS
Dz.U. 2011 Nr 174 poz. 1039 USTAWA z dnia 15 lipca 2011 r. o zawodach pielęgniarki i położnej
EOS
    to_xml(node).should ==
'<preface>
  <docNumber>Dz.U. 2011 Nr 174 poz. 1039 </docNumber>
  <docType>statute</docType>
  <docDate>z dnia 15 lipca 2011 r. </docDate>
  <docTitle>
    <p>o zawodach pielęgniarki i położnej</p>
  </docTitle>
</preface>'    
  end
end

  #-------------------------------------------------------------------------------
  # Multiple law unit hierarchy levels.

  describe 'ENTITY: Multiple law unit hierarchy levels.' do
    it 'ENTITY VARIATION: Ordinance.' do
      node = parse :body, <<EOS
DZIAŁ I

Projekt ustawy

Rozdział 7. Oznaczanie przepisów ustawy i ich systematyzacja

§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.

§ 55.
1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
2. Artykuł powinien być w miarę możliwości jednozdaniowy.
3. Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).
4. Podział artykułu na ustępy wprowadza się także w przypadku, gdy między zdaniami wyrażającymi samodzielne myśli występują powiązania treściowe, ale treść żadnego z nich nie jest na tyle istotna, aby wydzielić ją w odrębny artykuł.

§ 56.
1. W obrębie artykułu (ustępu) zawierającego wyliczenie wyróżnia się dwie części: wprowadzenie do wyliczenia oraz punkty. Wyliczenie może kończyć się częścią wspólną, odnoszącą się do wszystkich punktów. Po części wspólnej nie dodaje się kolejnej samodzielnej myśli; w razie potrzeby formułuje się ją w kolejnym ustępie.
2. W obrębie punktów można dokonać dalszego wyliczenia, wprowadzając litery.
EOS

      to_xml(node).should ==
'<body>
  <division id="division-I">
    <num>I</num>
    <subparagraph id="division-I.subparagraph-0">
      <content>
        <p>Projekt ustawy</p>
      </content>
    </subparagraph>
    <chapter id="division-I.chapter-7">
      <num>7</num>
      <heading>Oznaczanie przepisów ustawy i ich systematyzacja</heading>
      <section id="section-54" refersTo="ordinance">
        <num>54</num>
        <content>
          <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
        </content>
      </section>
      <section id="section-55" refersTo="ordinance">
        <num>55</num>
        <subsection id="section-55.subsection-1" refersTo="noncode_level1_unit">
          <num>1</num>
          <content>
            <p>Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
          </content>
        </subsection>
        <subsection id="section-55.subsection-2" refersTo="noncode_level1_unit">
          <num>2</num>
          <content>
            <p>Artykuł powinien być w miarę możliwości jednozdaniowy.</p>
          </content>
        </subsection>
        <subsection id="section-55.subsection-3" refersTo="noncode_level1_unit">
          <num>3</num>
          <content>
            <p>Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).</p>
          </content>
        </subsection>
        <subsection id="section-55.subsection-4" refersTo="noncode_level1_unit">
          <num>4</num>
          <content>
            <p>Podział artykułu na ustępy wprowadza się także w przypadku, gdy między zdaniami wyrażającymi samodzielne myśli występują powiązania treściowe, ale treść żadnego z nich nie jest na tyle istotna, aby wydzielić ją w odrębny artykuł.</p>
          </content>
        </subsection>
      </section>
      <section id="section-56" refersTo="ordinance">
        <num>56</num>
        <subsection id="section-56.subsection-1" refersTo="noncode_level1_unit">
          <num>1</num>
          <content>
            <p>W obrębie artykułu (ustępu) zawierającego wyliczenie wyróżnia się dwie części: wprowadzenie do wyliczenia oraz punkty. Wyliczenie może kończyć się częścią wspólną, odnoszącą się do wszystkich punktów. Po części wspólnej nie dodaje się kolejnej samodzielnej myśli; w razie potrzeby formułuje się ją w kolejnym ustępie.</p>
          </content>
        </subsection>
        <subsection id="section-56.subsection-2" refersTo="noncode_level1_unit">
          <num>2</num>
          <content>
            <p>W obrębie punktów można dokonać dalszego wyliczenia, wprowadzając litery.</p>
          </content>
        </subsection>
      </section>
    </chapter>
  </division>
</body>'
    end

    it 'ENTITY VARIATION: Noncode statute, all levels.' do
      node = parse :body, <<EOS
KSIĘGA ÓSMA
Vvv
TYTUŁ XVI
Xxx
Dział 987
Yyy
Rozdział 654
Zzz
Art. 123.
456. Aaa aaa
789) Bbb bbb
abc) Ccc ccc
@@INDENT2@@– Ddd ddd
@@INDENT3@@– – Eee eee
@@INDENT4@@– – – Fff fff
EOS
      to_xml(node).should ==
'<body>
  <book id="book-8">
    <num>8</num>
    <heading>Vvv</heading>
    <title id="book-8.title-XVI">
      <num>XVI</num>
      <heading>Xxx</heading>
      <division id="book-8.title-XVI.division-987">
        <num>987</num>
        <heading>Yyy</heading>
        <chapter id="book-8.title-XVI.division-987.chapter-654">
          <num>654</num>
          <heading>Zzz</heading>
          <section id="section-123" refersTo="statute">
            <num>123</num>
            <subsection id="section-123.subsection-456" refersTo="noncode_level1_unit">
              <num>456</num>
              <intro>
                <p>Aaa aaa</p>
              </intro>
              <point id="section-123.subsection-456.point-789" refersTo="point_unit">
                <num>789)</num>
                <intro>
                  <p>Bbb bbb</p>
                </intro>
                <point id="section-123.subsection-456.point-789.point-abc" refersTo="letter_unit">
                  <num>abc)</num>
                  <intro>
                    <p>Ccc ccc</p>
                  </intro>
                  <list id="section-123.subsection-456.point-789.point-abc.list-0">
                    <indent id="section-123.subsection-456.point-789.point-abc.list-0.indent-0" refersTo="single_tiret">
                      <content>
                        <p>Ddd ddd</p>
                      </content>
                    </indent>
                    <list id="section-123.subsection-456.point-789.point-abc.list-0.list-1">
                      <indent id="section-123.subsection-456.point-789.point-abc.list-0.list-1.indent-0" refersTo="double_tiret">
                        <content>
                          <p>Eee eee</p>
                        </content>
                      </indent>
                      <list id="section-123.subsection-456.point-789.point-abc.list-0.list-1.list-1">
                        <indent id="section-123.subsection-456.point-789.point-abc.list-0.list-1.list-1.indent-0" refersTo="triple_tiret">
                          <content>
                            <p>Fff fff</p>
                          </content>
                        </indent>
                      </list>
                    </list>
                  </list>
                </point>
              </point>
            </subsection>
          </section>
        </chapter>
      </division>
    </title>
  </book>
</body>'
    end
  end



  #-------------------------------------------------------------------------------
  # Divisions

  describe 'divisions' do
    it 'should handle divisions' do
      node = parse :division, <<EOS
DZIAŁ I
Projekt ustawy

Rozdział 7. Oznaczanie przepisów ustawy i ich systematyzacja

§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.
EOS
      to_xml(node).should ==
'<division id="division-I">
  <num>I</num>
  <heading>Projekt ustawy</heading>
  <chapter id="division-I.chapter-7">
    <num>7</num>
    <heading>Oznaczanie przepisów ustawy i ich systematyzacja</heading>
    <section id="section-54" refersTo="ordinance">
      <num>54</num>
      <content>
        <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
      </content>
    </section>
  </chapter>
</division>'
    end
  end



  #-------------------------------------------------------------------------------
  # Subdivisions

  describe 'subdivisions' do
    it 'should handle subdivisions' do
      node = parse :subdivision, <<EOS
ODDZIAŁ I
Projekt ustawy

§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.
EOS
      to_xml(node).should ==
'<subdivision id="subdivision-I">
  <num>I</num>
  <heading>Projekt ustawy</heading>
  <section id="section-54" refersTo="ordinance">
    <num>54</num>
    <content>
      <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
    </content>
  </section>
</subdivision>'
    end
  end



  #-------------------------------------------------------------------------------
  # Statute level 0 units

  describe 'ENTITY: Statute level 0 unit (Polish "artykuł").' do
    it 'ENTITY VARIATION: Basic one-line.' do
      node = parse :statute_level0_unit, <<EOS
Art. 1. Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych
EOS
      to_xml(node).should ==
'<section id="section-1" refersTo="statute">
  <num>1</num>
  <content>
    <p>Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych</p>
  </content>
</section>'
    end

    it 'ENTITY VARIATION: Containing blank lines.' do
      node = parse :statute_level0_unit, <<EOS
Art. 1.

Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych
EOS
      to_xml(node).should ==
'<section id="section-1" refersTo="statute">
  <num>1</num>
  <content>
    <p>Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych</p>
  </content>
</section>'
    end

    it 'ENTITY VARIATION: Multiple, adjacent, basic.' do
      node = parse :body, <<EOS
Art. 1. Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych
Art. 2. Something else
EOS
      to_xml(node).should ==
'<body>
  <section id="section-1" refersTo="statute">
    <num>1</num>
    <content>
      <p>Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych</p>
    </content>
  </section>
  <section id="section-2" refersTo="statute">
    <num>2</num>
    <content>
      <p>Something else</p>
    </content>
  </section>
</body>'
    end

    it 'ENTITY VARIATION: Having nested content.' do
      node = parse :statute_level0_unit, <<EOS
Art. 2.
1. Przepisów ustawy nie stosuje się do:
1) przychodów z działalności rolniczej, z wyjątkiem przychodów z działów specjalnych produkcji rolnej;
2) przychodów z gospodarki leśnej w rozumieniu ustawy o lasach;
EOS
      to_xml(node).should ==
'<section id="section-2" refersTo="statute">
  <num>2</num>
  <subsection id="section-2.subsection-1" refersTo="noncode_level1_unit">
    <num>1</num>
    <intro>
      <p>Przepisów ustawy nie stosuje się do:</p>
    </intro>
    <point id="section-2.subsection-1.point-1" refersTo="point_unit">
      <num>1)</num>
      <content>
        <p>przychodów z działalności rolniczej, z wyjątkiem przychodów z działów specjalnych produkcji rolnej;</p>
      </content>
    </point>
    <point id="section-2.subsection-1.point-2" refersTo="point_unit">
      <num>2)</num>
      <content>
        <p>przychodów z gospodarki leśnej w rozumieniu ustawy o lasach;</p>
      </content>
    </point>
  </subsection>
</section>'
    end

    it 'ENTITY VARIATION: With superscript number.' do
      node = parse :statute_level0_unit, <<EOS
Art. 123@@SUPERSCRIPT@@456##SUPERSCRIPT##. Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych
EOS
      to_xml(node).should ==
'<section id="section-123^456" refersTo="statute">
  <num>123^456</num>
  <content>
    <p>Ustawa reguluje opodatkowanie podatkiem dochodowym dochodów osób fizycznych</p>
  </content>
</section>'
    end
  end



  #-------------------------------------------------------------------------------
  # Ordinance level 0 units.

  describe 'ENTITY: Ordinance level 0 unit (Polish "paragraf").' do
    it 'ENTITY VARIATION: Basic with newline.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 5.

Przepisy ustawy redaguje się zwięźle i syntetycznie, unikając nadmiernej szczegółowości, a zarazem w sposób, w jaki opisuje się typowe sytuacje występujące w dziedzinie spraw regulowanych tą ustawą.
EOS

      to_xml(node).should ==
'<section id="section-5" refersTo="ordinance">
  <num>5</num>
  <content>
    <p>Przepisy ustawy redaguje się zwięźle i syntetycznie, unikając nadmiernej szczegółowości, a zarazem w sposób, w jaki opisuje się typowe sytuacje występujące w dziedzinie spraw regulowanych tą ustawą.</p>
  </content>
</section>'
    end

    it 'ENTITY VARIATION: Basic one-line.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.
EOS

      to_xml(node).should ==
'<section id="section-54" refersTo="ordinance">
  <num>54</num>
  <content>
    <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
  </content>
</section>'
    end

    it 'ENTITY VARIATION: Basic with nested level 1 units.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 55.
1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
2. Artykuł powinien być w miarę możliwości jednozdaniowy.
3. Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).
EOS

      to_xml(node).should ==
'<section id="section-55" refersTo="ordinance">
  <num>55</num>
  <subsection id="section-55.subsection-1" refersTo="noncode_level1_unit">
    <num>1</num>
    <content>
      <p>Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
    </content>
  </subsection>
  <subsection id="section-55.subsection-2" refersTo="noncode_level1_unit">
    <num>2</num>
    <content>
      <p>Artykuł powinien być w miarę możliwości jednozdaniowy.</p>
    </content>
  </subsection>
  <subsection id="section-55.subsection-3" refersTo="noncode_level1_unit">
    <num>3</num>
    <content>
      <p>Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).</p>
    </content>
  </subsection>
</section>'
    end

    it 'ENTITY VARIATION: With first nested level 1 unit on the same line as prefix.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 55. 1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
3. Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).
EOS

      to_xml(node).should ==
'<section id="section-55" refersTo="ordinance">
  <num>55</num>
  <intro>
    <p>1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
  </intro>
  <subsection id="section-55.subsection-3" refersTo="noncode_level1_unit">
    <num>3</num>
    <content>
      <p>Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).</p>
    </content>
  </subsection>
</section>'
    end

    it 'ENTITY VARIATION: With list of points having an introduction.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.

Something here

1) a point
2) second point
EOS

      to_xml(node).should ==
'<section id="section-54" refersTo="ordinance">
  <num>54</num>
  <intro>
    <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
  </intro>
  <subparagraph id="section-54.subparagraph-0">
    <content>
      <p>Something here</p>
    </content>
  </subparagraph>
  <point id="section-54.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>a point</p>
    </content>
  </point>
  <point id="section-54.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>second point</p>
    </content>
  </point>
</section>'
    end

    it 'ENTITY VARIATION: With text referring to an "artykuł".' do
      node = parse :ordinance_level0_unit, <<EOS
§ 54. Art 1. is changed...
EOS

      to_xml(node).should ==
'<section id="section-54" refersTo="ordinance">
  <num>54</num>
  <content>
    <p>Art 1. is changed...</p>
  </content>
</section>'
    end

    it 'ENTITY VARIATION: With superscript.' do
      node = parse :ordinance_level0_unit, <<EOS
§ 5c@@SUPERSCRIPT@@6a##SUPERSCRIPT##. Przepisy ustawy redaguje się zwięźle i syntetycznie, unikając nadmiernej szczegółowości, a zarazem w sposób, w jaki opisuje się typowe sytuacje występujące w dziedzinie spraw regulowanych tą ustawą.
EOS

      to_xml(node).should ==
'<section id="section-5c^6a" refersTo="ordinance">
  <num>5c^6a</num>
  <content>
    <p>Przepisy ustawy redaguje się zwięźle i syntetycznie, unikając nadmiernej szczegółowości, a zarazem w sposób, w jaki opisuje się typowe sytuacje występujące w dziedzinie spraw regulowanych tą ustawą.</p>
  </content>
</section>'
    end
  end



  #-------------------------------------------------------------------------------
  # Noncode level 1 units.

  describe 'ENTITY: Noncode level 1 unit (Polish "ustęp").' do
    it 'ENTITY VARIATION: Basic one-line.' do
      node = parse :noncode_level1_unit, <<EOS
1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="noncode_level1_unit">
  <num>1</num>
  <content>
    <p>Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
  </content>
</subsection>'
    end

    it 'ENTITY VARIATION: Empty.' do
      node = parse :noncode_level1_unit, <<EOS
1.
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="noncode_level1_unit">
  <num>1</num>
  <content>
    <p/>
  </content>
</subsection>'
    end

    it 'ENTITY VARIATION: With whitespace and newlines.' do
      node = parse :noncode_level1_unit, <<EOS
1.

foo bar
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="noncode_level1_unit">
  <num>1</num>
  <content>
    <p>foo bar</p>
  </content>
</subsection>'
    end

    it 'ENTITY VARIATION: With nested points.' do
      node = parse :noncode_level1_unit, <<EOS
2. W ustawie należy unikać posługiwania się:
1) określeniami specjalistycznymi, o ile ich użycie nie jest powodowane zapewnieniem należytej precyzji tekstu;
2) określeniami lub zapożyczeniami obcojęzycznymi, chyba że nie mają dokładnego odpowiednika w języku polskim;
3) nowo tworzonymi pojęciami lub strukturami językowymi, chyba że w dotychczasowym słownictwie polskim brak jest odpowiedniego określenia.
EOS

      to_xml(node).should ==
'<subsection id="subsection-2" refersTo="noncode_level1_unit">
  <num>2</num>
  <intro>
    <p>W ustawie należy unikać posługiwania się:</p>
  </intro>
  <point id="subsection-2.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>określeniami specjalistycznymi, o ile ich użycie nie jest powodowane zapewnieniem należytej precyzji tekstu;</p>
    </content>
  </point>
  <point id="subsection-2.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>określeniami lub zapożyczeniami obcojęzycznymi, chyba że nie mają dokładnego odpowiednika w języku polskim;</p>
    </content>
  </point>
  <point id="subsection-2.point-3" refersTo="point_unit">
    <num>3)</num>
    <content>
      <p>nowo tworzonymi pojęciami lub strukturami językowymi, chyba że w dotychczasowym słownictwie polskim brak jest odpowiedniego określenia.</p>
    </content>
  </point>
</subsection>'
    end

    it 'ENTITY VARIATION: Containing nested points which refer to "artykuł"s.' do
      node = parse :noncode_level1_unit, <<EOS
2. W ustawie należy unikać posługiwania się:
1) art. 1
2) art. 2
EOS

      to_xml(node).should ==
'<subsection id="subsection-2" refersTo="noncode_level1_unit">
  <num>2</num>
  <intro>
    <p>W ustawie należy unikać posługiwania się:</p>
  </intro>
  <point id="subsection-2.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>art. 1</p>
    </content>
  </point>
  <point id="subsection-2.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>art. 2</p>
    </content>
  </point>
</subsection>'
    end
  end



  #-------------------------------------------------------------------------------
  # Points

  describe 'ENTITY: Point (Polish "punkt").' do
    it 'ENTITY VARIATION: Basic.' do
      node = parse :point, <<EOS
1) szczegółowy tryb i terminy rozpatrywania wniosków o udzielenie finansowego wsparcia;
EOS

      to_xml(node, 'prefix.', 0).should ==
'<point id="prefix.point-1" refersTo="point_unit">
  <num>1)</num>
  <content>
    <p>szczegółowy tryb i terminy rozpatrywania wniosków o udzielenie finansowego wsparcia;</p>
  </content>
</point>'
    end

    it 'ENTITY VARIATION: With letters underneath.' do
      node = parse :point, <<EOS
1) dokumenty potwierdzające prawo własności albo prawo użytkowania wieczystego nieruchomości, której dotyczy przedsięwzięcie albo na której położony jest budynek, którego budowę, remont lub przebudowę zamierza się przepro- wadzić w ramach realizacji przedsięwzięcia, w tym:

a) oryginał albo potwierdzoną za zgodność z oryginałem kopię wypisu i wyrysu z rejestru gruntów wszystkich dzia- łek ewidencyjnych, na których realizowane jest przedsięwzięcie, wydanego nie wcześniej niż 3 miesiące przed dniem złożenia wniosku, oraz

b) numer księgi wieczystej;
EOS

      to_xml(node, 'prefix.', 0).should ==
'<point id="prefix.point-1" refersTo="point_unit">
  <num>1)</num>
  <intro>
    <p>dokumenty potwierdzające prawo własności albo prawo użytkowania wieczystego nieruchomości, której dotyczy przedsięwzięcie albo na której położony jest budynek, którego budowę, remont lub przebudowę zamierza się przepro- wadzić w ramach realizacji przedsięwzięcia, w tym:</p>
  </intro>
  <point id="prefix.point-1.point-a" refersTo="letter_unit">
    <num>a)</num>
    <content>
      <p>oryginał albo potwierdzoną za zgodność z oryginałem kopię wypisu i wyrysu z rejestru gruntów wszystkich dzia- łek ewidencyjnych, na których realizowane jest przedsięwzięcie, wydanego nie wcześniej niż 3 miesiące przed dniem złożenia wniosku, oraz</p>
    </content>
  </point>
  <point id="prefix.point-1.point-b" refersTo="letter_unit">
    <num>b)</num>
    <content>
      <p>numer księgi wieczystej;</p>
    </content>
  </point>
</point>'
    end
  end



  #-------------------------------------------------------------------------------
  # Letters

  describe 'ENTITY: Letter (Polish "litera").' do

    it 'ENTITY VARIATION: With tirets underneath.' do
      node = parse :letter_unit, <<EOS
b) liczby:
@@INDENT2@@– tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
@@INDENT2@@– mieszkań chronionych,
@@INDENT2@@– lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,
@@INDENT2@@– tymczasowych pomieszczeń,
@@INDENT2@@– miejsc w noclegowniach, schroniskach dla bezdomnych i ogrzewalniach,
EOS
      to_xml(node, 'prefix.', 0).should ==
'<point id="prefix.point-b" refersTo="letter_unit">
  <num>b)</num>
  <intro>
    <p>liczby:</p>
  </intro>
  <list id="prefix.point-b.list-0">
    <indent id="prefix.point-b.list-0.indent-0" refersTo="single_tiret">
      <content>
        <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
      </content>
    </indent>
    <indent id="prefix.point-b.list-0.indent-1" refersTo="single_tiret">
      <content>
        <p>mieszkań chronionych,</p>
      </content>
    </indent>
    <indent id="prefix.point-b.list-0.indent-2" refersTo="single_tiret">
      <content>
        <p>lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,</p>
      </content>
    </indent>
    <indent id="prefix.point-b.list-0.indent-3" refersTo="single_tiret">
      <content>
        <p>tymczasowych pomieszczeń,</p>
      </content>
    </indent>
    <indent id="prefix.point-b.list-0.indent-4" refersTo="single_tiret">
      <content>
        <p>miejsc w noclegowniach, schroniskach dla bezdomnych i ogrzewalniach,</p>
      </content>
    </indent>
  </list>
</point>'
    end
  end



  #-------------------------------------------------------------------------------
  # Tirets

  describe 'ENTITY: Tirets.' do
    it 'ENTITY VARIATION: Basic.' do
      node = parse :tiret, <<EOS
@@INDENT2@@– tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="single_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Empty.' do
      node = parse :tiret, <<EOS
@@INDENT2@@– 
@@INDENT2@@– 
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="single_tiret">
    <content>
      <p/>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="single_tiret">
    <content>
      <p/>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Multiple.' do
      node = parse :tiret, <<EOS
@@INDENT2@@– tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
@@INDENT2@@– mieszkań chronionych,
@@INDENT2@@– lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="single_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="single_tiret">
    <content>
      <p>mieszkań chronionych,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-2" refersTo="single_tiret">
    <content>
      <p>lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,</p>
    </content>
  </indent>
</list>'
    end
  end



  #-------------------------------------------------------------------------------
  # Double tirets

  describe 'ENTITY: Double tirets.' do
    it 'ENTITY VARIATION: Basic.' do
      node = parse :double_tiret, <<EOS
@@INDENT3@@– – tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="double_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Empty.' do
      node = parse :double_tiret, <<EOS
@@INDENT3@@– – 
@@INDENT3@@– – 
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="double_tiret">
    <content>
      <p/>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="double_tiret">
    <content>
      <p/>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Multiple.' do
      node = parse :double_tiret, <<EOS
@@INDENT3@@– – tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
@@INDENT3@@– – mieszkań chronionych,
@@INDENT3@@– – lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="double_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="double_tiret">
    <content>
      <p>mieszkań chronionych,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-2" refersTo="double_tiret">
    <content>
      <p>lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,</p>
    </content>
  </indent>
</list>'
    end
  end



  #-------------------------------------------------------------------------------
  # Triple tirets

  describe 'ENTITY: Triple tirets.' do
    it 'ENTITY VARIATION: Basic.' do
      node = parse :triple_tiret, <<EOS
@@INDENT4@@– – – tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="triple_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Empty.' do
      node = parse :triple_tiret, <<EOS
@@INDENT4@@– – – 
@@INDENT4@@– – – 
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="triple_tiret">
    <content>
      <p/>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="triple_tiret">
    <content>
      <p/>
    </content>
  </indent>
</list>'
    end

    it 'ENTITY VARIATION: Multiple.' do
      node = parse :triple_tiret, <<EOS
@@INDENT4@@– – – tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,
@@INDENT4@@– – – mieszkań chronionych,
@@INDENT4@@– – – lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,
EOS

      to_xml(node, 'prefix.', 0).should ==
'<list id="prefix.list-0">
  <indent id="prefix.list-0.indent-0" refersTo="triple_tiret">
    <content>
      <p>tworzonych lokali wchodzących w skład mieszkaniowego zasobu gminy,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-1" refersTo="triple_tiret">
    <content>
      <p>mieszkań chronionych,</p>
    </content>
  </indent>
  <indent id="prefix.list-0.indent-2" refersTo="triple_tiret">
    <content>
      <p>lokali mieszkalnych powstających z udziałem gminy albo związku międzygminnego w wyniku realizacji przedsięwzięć, o których mowa w art. 5 ust. 1 i art. 5a ust. 1 ustawy,</p>
    </content>
  </indent>
</list>'
    end
  end



  #-------------------------------------------------------------------------------
  # Dashed wrap-up for points
  
  describe 'ENTITY: Dashed section appearing immediately after a list of points.' do
    it 'ENTITY VARIATION: In statute level 0' do
      node = parse :statute_level0_unit, <<EOS
Art. 1. The following rights:
1) the right to X
2) the right to Y
@@INDENT0@@– shall not be abrogated
EOS

      to_xml(node).should ==
'<section id="section-1" refersTo="statute">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="section-1.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>the right to X</p>
    </content>
  </point>
  <point id="section-1.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated
</p>
  </wrapUp>
</section>'
    end

    it 'ENTITY VARIATION: In ordinance level 0' do
      node = parse :ordinance_level0_unit, <<EOS
§ 1. The following rights:
1) the right to X
2) the right to Y
@@INDENT0@@– shall not be abrogated
EOS

      to_xml(node).should ==
'<section id="section-1" refersTo="ordinance">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="section-1.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>the right to X</p>
    </content>
  </point>
  <point id="section-1.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated
</p>
  </wrapUp>
</section>'
    end

    it 'ENTITY VARIATION: In noncode level 1' do
      node = parse :noncode_level1_unit, <<EOS
1. The following rights:
1) the right to X
2) the right to Y
@@INDENT0@@– shall not be abrogated
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="noncode_level1_unit">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="subsection-1.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>the right to X</p>
    </content>
  </point>
  <point id="subsection-1.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated
</p>
  </wrapUp>
</subsection>'
    end

    it 'ENTITY VARIATION: In code level 1' do
      node = parse :code_level1_unit, <<EOS
§ 1. The following rights:
1) the right to X
2) the right to Y
@@INDENT0@@– shall not be abrogated
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="code_level1_unit">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="subsection-1.point-1" refersTo="point_unit">
    <num>1)</num>
    <content>
      <p>the right to X</p>
    </content>
  </point>
  <point id="subsection-1.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated
</p>
  </wrapUp>
</subsection>'
    end
    
    it 'ENTITY VARIATION: Exceptionally (and incorrectly), lawmakers use letters at level 1.' do
      node = parse :noncode_level1_unit, <<EOS
1. The following rights:
a) the right to X
b) the right to Y
@@INDENT0@@– shall not be abrogated
EOS

      to_xml(node).should ==
'<subsection id="subsection-1" refersTo="noncode_level1_unit">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="subsection-1.point-a" refersTo="letter_unit">
    <num>a)</num>
    <content>
      <p>the right to X</p>
    </content>
  </point>
  <point id="subsection-1.point-b" refersTo="letter_unit">
    <num>b)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated
</p>
  </wrapUp>
</subsection>'
    end    
  end



  #-------------------------------------------------------------------------------
  # Dashed wrap-up for letters
    
  describe 'ENTITY: Dashed section appearing immediately after a list of letters.' do
    it 'ENTITY VARIATION: Basic' do
      node = parse :statute_level0_unit, <<EOS
Art. 1. The following rights:
1) right of passage:
a) through the town square,
b) through the town marketplace
@@INDENT1@@– assuming it is Sunday
2) the right to Y
@@INDENT0@@– shall not be abrogated.
EOS

      to_xml(node).should ==
'<section id="section-1" refersTo="statute">
  <num>1</num>
  <intro>
    <p>The following rights:</p>
  </intro>
  <point id="section-1.point-1" refersTo="point_unit">
    <num>1)</num>
    <intro>
      <p>right of passage:</p>
    </intro>
    <point id="section-1.point-1.point-a" refersTo="letter_unit">
      <num>a)</num>
      <content>
        <p>through the town square,</p>
      </content>
    </point>
    <point id="section-1.point-1.point-b" refersTo="letter_unit">
      <num>b)</num>
      <content>
        <p>through the town marketplace</p>
      </content>
    </point>
    <wrapUp refersTo="wrap_up_for_letters">
      <p>– assuming it is Sunday
</p>
    </wrapUp>
  </point>
  <point id="section-1.point-2" refersTo="point_unit">
    <num>2)</num>
    <content>
      <p>the right to Y</p>
    </content>
  </point>
  <wrapUp refersTo="wrap_up_for_points">
    <p>– shall not be abrogated.
</p>
  </wrapUp>
</section>'
    end
  end
  
end
