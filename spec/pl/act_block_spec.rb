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
  # Basics

  describe 'full test' do
    it 'should handle a full hierarchy' do
      node = parse :body, <<EOS
DZIAŁ I

Projekt ustawy

Rozdział 7. Oznaczanie przepisów ustawy i ich systematyzacja

§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.

§ 55. 1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
2. Artykuł powinien być w miarę możliwości jednozdaniowy.
3. Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).
4. Podział artykułu na ustępy wprowadza się także w przypadku, gdy między zdaniami wyrażającymi samodzielne myśli występują powiązania treściowe, ale treść żadnego z nich nie jest na tyle istotna, aby wydzielić ją w odrębny artykuł.

§ 56. 1. W obrębie artykułu (ustępu) zawierającego wyliczenie wyróżnia się dwie części: wprowadzenie do wyliczenia oraz punkty. Wyliczenie może kończyć się częścią wspólną, odnoszącą się do wszystkich punktów. Po części wspólnej nie dodaje się kolejnej samodzielnej myśli; w razie potrzeby formułuje się ją w kolejnym ustępie.
2. W obrębie punktów można dokonać dalszego wyliczenia, wprowadzając litery.
EOS

      to_xml(node).should == '<body>
  <division id="division-I">
    <num>I</num>
    <paragraph id="division-I.paragraph-0">
      <content>
        <p>Projekt ustawy</p>
      </content>
    </paragraph>
    <chapter id="chapter-7">
      <num>7</num>
      <heading>Oznaczanie przepisów ustawy i ich systematyzacja</heading>
      <section id="section-54">
        <num>54.</num>
        <content>
          <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
        </content>
      </section>
      <section id="section-55">
        <num>55.</num>
        <paragraph id="section-55.paragraph-1">
          <num>1.</num>
          <content>
            <p>Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
          </content>
        </paragraph>
        <paragraph id="section-55.paragraph-2">
          <num>2.</num>
          <content>
            <p>Artykuł powinien być w miarę możliwości jednozdaniowy.</p>
          </content>
        </paragraph>
        <paragraph id="section-55.paragraph-3">
          <num>3.</num>
          <content>
            <p>Jeżeli samodzielną myśl wyraża zespół zdań, dokonuje się podziału artykułu na ustępy. W ustawie określanej jako "kodeks" ustępy oznacza się paragrafami (§).</p>
          </content>
        </paragraph>
        <paragraph id="section-55.paragraph-4">
          <num>4.</num>
          <content>
            <p>Podział artykułu na ustępy wprowadza się także w przypadku, gdy między zdaniami wyrażającymi samodzielne myśli występują powiązania treściowe, ale treść żadnego z nich nie jest na tyle istotna, aby wydzielić ją w odrębny artykuł.</p>
          </content>
        </paragraph>
      </section>
      <section id="section-56">
        <num>56.</num>
        <paragraph id="section-56.paragraph-1">
          <num>1.</num>
          <content>
            <p>W obrębie artykułu (ustępu) zawierającego wyliczenie wyróżnia się dwie części: wprowadzenie do wyliczenia oraz punkty. Wyliczenie może kończyć się częścią wspólną, odnoszącą się do wszystkich punktów. Po części wspólnej nie dodaje się kolejnej samodzielnej myśli; w razie potrzeby formułuje się ją w kolejnym ustępie.</p>
          </content>
        </paragraph>
        <paragraph id="section-56.paragraph-2">
          <num>2.</num>
          <content>
            <p>W obrębie punktów można dokonać dalszego wyliczenia, wprowadzając litery.</p>
          </content>
        </paragraph>
      </section>
    </chapter>
  </division>
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
      to_xml(node).should == '<division id="division-I">
  <num>I</num>
  <heading>Projekt ustawy</heading>
  <chapter id="chapter-7">
    <num>7</num>
    <heading>Oznaczanie przepisów ustawy i ich systematyzacja</heading>
    <section id="section-54">
      <num>54.</num>
      <content>
        <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
      </content>
    </section>
  </chapter>
</division>'
    end
  end

  #-------------------------------------------------------------------------------
  # Divisions

  describe 'subdivisions' do
    it 'should handle subdivisions' do
      node = parse :subdivision, <<EOS
ODDZIAŁ I
Projekt ustawy

§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.
EOS
      to_xml(node).should == '<subdivision id="subdivision-I">
  <num>I</num>
  <heading>Projekt ustawy</heading>
  <section id="section-54">
    <num>54.</num>
    <content>
      <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
    </content>
  </section>
</subdivision>'
    end
  end

  #-------------------------------------------------------------------------------
  # Paragraph

  describe 'paragraph' do
    it 'should handle simple para' do
      node = parse :paragraph, <<EOS
1. Każdą samodzielną myśl ujmuje się w odrębny artykuł.
EOS

      to_xml(node).should == '<paragraph id="paragraph-1">
  <num>1.</num>
  <content>
    <p>Każdą samodzielną myśl ujmuje się w odrębny artykuł.</p>
  </content>
</paragraph>'
    end

    it 'should handle an empty para' do
      node = parse :paragraph, <<EOS
1.
EOS

      to_xml(node).should == '<paragraph id="paragraph-1">
  <num>1.</num>
  <content>
    <p/>
  </content>
</paragraph>'
    end

    it 'should handle paragraphs with points' do
      node = parse :paragraph, <<EOS
2. W ustawie należy unikać posługiwania się:
1) określeniami specjalistycznymi, o ile ich użycie nie jest powodowane zapewnieniem należytej precyzji tekstu;
2) określeniami lub zapożyczeniami obcojęzycznymi, chyba że nie mają dokładnego odpowiednika w języku polskim;
3) nowo tworzonymi pojęciami lub strukturami językowymi, chyba że w dotychczasowym słownictwie polskim brak jest odpowiedniego określenia.
EOS

      to_xml(node).should == '<paragraph id="paragraph-2">
  <num>2.</num>
  <intro>
    <p>W ustawie należy unikać posługiwania się:</p>
  </intro>
  <point id="paragraph-2.point-1">
    <num>1)</num>
    <content>
      <p>określeniami specjalistycznymi, o ile ich użycie nie jest powodowane zapewnieniem należytej precyzji tekstu;</p>
    </content>
  </point>
  <point id="paragraph-2.point-2">
    <num>2)</num>
    <content>
      <p>określeniami lub zapożyczeniami obcojęzycznymi, chyba że nie mają dokładnego odpowiednika w języku polskim;</p>
    </content>
  </point>
  <point id="paragraph-2.point-3">
    <num>3)</num>
    <content>
      <p>nowo tworzonymi pojęciami lub strukturami językowymi, chyba że w dotychczasowym słownictwie polskim brak jest odpowiedniego określenia.</p>
    </content>
  </point>
</paragraph>'
    end
  end

  #-------------------------------------------------------------------------------
  # Section

  describe 'section' do
    it 'should handle section with un-numbered para' do
      node = parse :section, <<EOS
§ 5.

Przepisy ustawy redaguje si´ zwi´êle i syntetycznie, unikajàc nadmiernej szczegó∏owoÊci, a zarazem w sposób, w jaki opisuje si´ typowe sytuacje wyst´pujàce w dziedzinie spraw regulowanych tà ustawà.
EOS

      to_xml(node).should == '<section id="section-5">
  <num>5.</num>
  <content>
    <p>Przepisy ustawy redaguje si´ zwi´êle i syntetycznie, unikajàc nadmiernej szczegó∏owoÊci, a zarazem w sposób, w jaki opisuje si´ typowe sytuacje wyst´pujàce w dziedzinie spraw regulowanych tà ustawà.</p>
  </content>
</section>'
    end

    it 'should handle section with numbered para on the same line' do
      node = parse :section, <<EOS
§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.
EOS

      to_xml(node).should == '<section id="section-54">
  <num>54.</num>
  <content>
    <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
  </content>
</section>'
    end

    it 'should handle section with intro, para and points' do
      node = parse :section, <<EOS
§ 54. Podstawową jednostką redakcyjną ustawy jest artykuł.

Something here

1) a point
2) second point
EOS

      to_xml(node).should == '<section id="section-54">
  <num>54.</num>
  <intro>
    <p>Podstawową jednostką redakcyjną ustawy jest artykuł.</p>
  </intro>
  <paragraph id="section-54.paragraph-0">
    <content>
      <p>Something here</p>
    </content>
  </paragraph>
  <point id="section-54.point-1">
    <num>1)</num>
    <content>
      <p>a point</p>
    </content>
  </point>
  <point id="section-54.point-2">
    <num>2)</num>
    <content>
      <p>second point</p>
    </content>
  </point>
</section>'
    end
  end

end
