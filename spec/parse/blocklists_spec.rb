# encoding: UTF-8

require 'spec_helper'
require 'slaw'

describe Slaw::Parse::Blocklists do
  describe '#adjust_blocklists' do
    it 'should nest simple blocks' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1" renest="true">
              <item eId="sec__10__subsec_1__list_1__item_a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_iii">
                <num>(iii)</num>
                <p>item-iii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_aa">
                <num>(aa)</num>
                <p>item-aa</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_bb">
                <num>(bb)</num>
                <p>item-bb</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <item eId="sec__10__subsec_1__list_1__item_a">
                <num>(a)</num>
                <blockList eId="sec__10__subsec_1__list_1__item_a__list_1">
                  <listIntroduction>foo</listIntroduction>
                  <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                  <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_iii">
                    <num>(iii)</num>
                    <blockList eId="sec__10__subsec_1__list_1__item_a__list_1__item_iii__list_1">
                      <listIntroduction>item-iii</listIntroduction>
                      <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_iii__list_1__item_aa">
                        <num>(aa)</num>
                        <p>item-aa</p>
                      </item>
                      <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_iii__list_1__item_bb">
                        <num>(bb)</num>
                        <p>item-bb</p>
                      </item>
                    </blockList>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should jump back up a level' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1" renest="true">
              <item eId="sec__10__subsec_1__list_1__item_a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_c">
                <num>(c)</num>
                <p>item-c</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <item eId="sec__10__subsec_1__list_1__item_a">
                <num>(a)</num>
                <blockList eId="sec__10__subsec_1__list_1__item_a__list_1">
                  <listIntroduction>foo</listIntroduction>
                  <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item eId="sec__10__subsec_1__list_1__item_a__list_1__item_ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                </blockList>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_c">
                <num>(c)</num>
                <p>item-c</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle (i) correctly' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1" renest="true">
              <item eId="sec__10__subsec_1__list_1__item_h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_j">
                <num>(j)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <item eId="sec__10__subsec_1__list_1__item_h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_j">
                <num>(j)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle (u) (v) and (x) correctly' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1" renest="true">
              <item eId="sec__10__subsec_1__list_1__item_t">
                <num>(t)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_u">
                <num>(u)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_v">
                <num>(v)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_w">
                <num>(w)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_x">
                <num>(x)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <item eId="sec__10__subsec_1__list_1__item_t">
                <num>(t)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_u">
                <num>(u)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_v">
                <num>(v)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_w">
                <num>(w)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_x">
                <num>(x)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      )
    end


    # -------------------------------------------------------------------------

    it 'should handle (j) correctly' do
      doc = xml2doc(subsection(<<XML
              <blockList eId="sec__28__subsec_3__item_list2" renest="true">
                <item eId="sec__28__subsec_3__item_list2.g">
                  <num>(g)</num>
                  <p>all <term refersTo="#term-memorial_work" eId="trm381">memorial work</term> up to 150 mm in thickness must be securely attached to the base;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.h">
                  <num>(h)</num>
                  <p>all the components of <term refersTo="#term-memorial_work" eId="trm382">memorial work</term> must be completed before being brought into a <term refersTo="#term-cemetery" eId="trm383">cemetery</term>;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.i">
                  <num>(i)</num>
                  <p>footstones must consist of one solid piece;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.j">
                  <num>(j)</num>
                  <p>in all cases where <term refersTo="#term-memorial_work" eId="trm384">memorial work</term> rests on a base -</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.i">
                  <num>(i)</num>
                  <p>such <term refersTo="#term-memorial_work" eId="trm385">memorial work</term> must have a foundation;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.ii">
                  <num>(ii)</num>
                  <p>such <term refersTo="#term-memorial_work" eId="trm386">memorial work</term> must be set with cement mortar;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.iii">
                  <num>(iii)</num>
                  <p>the bottom base of a single <term refersTo="#term-memorial_work" eId="trm387">memorial work</term> must not be less than 900mm long 220 mm wide x 250 mm thick and that of a double <term refersTo="#term-memorial_work" eId="trm388">memorial work</term> not less than 2 286 mm long x 200 mm wide x 250 mm thick; and</p>
                </item>
              </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__28__subsec_3__item_list2">
              <item eId="sec__28__subsec_3__item_list2.g">
                <num>(g)</num>
                <p>all <term refersTo="#term-memorial_work" eId="trm381">memorial work</term> up to 150 mm in thickness must be securely attached to the base;</p>
              </item>
              <item eId="sec__28__subsec_3__item_list2.h">
                <num>(h)</num>
                <p>all the components of <term refersTo="#term-memorial_work" eId="trm382">memorial work</term> must be completed before being brought into a <term refersTo="#term-cemetery" eId="trm383">cemetery</term>;</p>
              </item>
              <item eId="sec__28__subsec_3__item_list2.i">
                <num>(i)</num>
                <p>footstones must consist of one solid piece;</p>
              </item>
              <item eId="sec__28__subsec_3__item_list2.j">
                <num>(j)</num>
                <blockList eId="sec__28__subsec_3__item_list2.j__list_1">
                  <listIntroduction>in all cases where <term refersTo="#term-memorial_work" eId="trm384">memorial work</term> rests on a base -</listIntroduction>
                  <item eId="sec__28__subsec_3__item_list2.j__list_1__item_i">
                    <num>(i)</num>
                    <p>such <term refersTo="#term-memorial_work" eId="trm385">memorial work</term> must have a foundation;</p>
                  </item>
                  <item eId="sec__28__subsec_3__item_list2.j__list_1__item_ii">
                    <num>(ii)</num>
                    <p>such <term refersTo="#term-memorial_work" eId="trm386">memorial work</term> must be set with cement mortar;</p>
                  </item>
                  <item eId="sec__28__subsec_3__item_list2.j__list_1__item_iii">
                    <num>(iii)</num>
                    <p>the bottom base of a single <term refersTo="#term-memorial_work" eId="trm387">memorial work</term> must not be less than 900mm long 220 mm wide x 250 mm thick and that of a double <term refersTo="#term-memorial_work" eId="trm388">memorial work</term> not less than 2 286 mm long x 200 mm wide x 250 mm thick; and</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------
    it 'should handle (I) correctly' do
      doc = xml2doc(subsection(<<XML
              <blockList eId="sec__28__subsec_3__item_list2" renest="true">
                <item eId="sec__28__subsec_3__item_list2.g">
                  <num>(g)</num>
                  <p>all memorial work up to 150 mm in thickness must be securely attached to the base;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.h">
                  <num>(h)</num>
                  <p>all the components of memorial work must be completed before being brought into a cemetery;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.i">
                  <num>(i)</num>
                  <p>item i</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.I">
                  <num>(I)</num>
                  <p>a subitem</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.II">
                  <num>(II)</num>
                  <p>another subitem</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.j">
                  <num>(j)</num>
                  <p>in all cases where memorial work rests on a base -</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.i">
                  <num>(i)</num>
                  <p>such memorial work must have a foundation;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.ii">
                  <num>(ii)</num>
                  <p>such memorial work must be set with cement mortar;</p>
                </item>
                <item eId="sec__28__subsec_3__item_list2.iii">
                  <num>(iii)</num>
                  <p>the bottom base of a single memorial work must not be less than 900mm long 220 mm wide x 250 mm thick and that of a double memorial work not less than 2 286 mm long x 200 mm wide x 250 mm thick; and</p>
                </item>
              </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__28__subsec_3__item_list2">
              <item eId="sec__28__subsec_3__item_list2.g">
                <num>(g)</num>
                <p>all memorial work up to 150 mm in thickness must be securely attached to the base;</p>
              </item>
              <item eId="sec__28__subsec_3__item_list2.h">
                <num>(h)</num>
                <p>all the components of memorial work must be completed before being brought into a cemetery;</p>
              </item>
              <item eId="sec__28__subsec_3__item_list2.i">
                <num>(i)</num>
                <blockList eId="sec__28__subsec_3__item_list2.i__list_1">
                  <listIntroduction>item i</listIntroduction>
                  <item eId="sec__28__subsec_3__item_list2.i__list_1__item_I">
                    <num>(I)</num>
                    <p>a subitem</p>
                  </item>
                  <item eId="sec__28__subsec_3__item_list2.i__list_1__item_II">
                    <num>(II)</num>
                    <p>another subitem</p>
                  </item>
                </blockList>
              </item>
              <item eId="sec__28__subsec_3__item_list2.j">
                <num>(j)</num>
                <blockList eId="sec__28__subsec_3__item_list2.j__list_2">
                  <listIntroduction>in all cases where memorial work rests on a base -</listIntroduction>
                  <item eId="sec__28__subsec_3__item_list2.j__list_2__item_i">
                    <num>(i)</num>
                    <p>such memorial work must have a foundation;</p>
                  </item>
                  <item eId="sec__28__subsec_3__item_list2.j__list_2__item_ii">
                    <num>(ii)</num>
                    <p>such memorial work must be set with cement mortar;</p>
                  </item>
                  <item eId="sec__28__subsec_3__item_list2.j__list_2__item_iii">
                    <num>(iii)</num>
                    <p>the bottom base of a single memorial work must not be less than 900mm long 220 mm wide x 250 mm thick and that of a double memorial work not less than 2 286 mm long x 200 mm wide x 250 mm thick; and</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should treat (aa) after (z) as siblings' do
      doc = xml2doc(subsection(<<XML
        <blockList eId="list0">
          <item eId="list0.y">
            <num>(y)</num>
            <p>foo</p>
          </item>
          <item eId="list0.z">
            <num>(z)</num>
            <p>item-z</p>
          </item>
          <item eId="list0.aa">
            <num>(aa)</num>
            <p>item-aa</p>
          </item>
          <item eId="list0.bb">
            <num>(bb)</num>
            <p>item-bb</p>
          </item>
        </blockList>
XML
    ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="list0">
              <item eId="list0.y">
                <num>(y)</num>
                <p>foo</p>
              </item>
              <item eId="list0.z">
                <num>(z)</num>
                <p>item-z</p>
              </item>
              <item eId="list0.aa">
                <num>(aa)</num>
                <p>item-aa</p>
              </item>
              <item eId="list0.bb">
                <num>(bb)</num>
                <p>item-bb</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should treat (AA) after (z) a sublist' do
      doc = xml2doc(subsection(<<XML
        <blockList eId="list0" renest="true">
          <item eId="list0.y">
            <num>(y)</num>
            <p>foo</p>
          </item>
          <item eId="list0.z">
            <num>(z)</num>
            <p>item-z</p>
          </item>
          <item eId="list0.AA">
            <num>(AA)</num>
            <p>item-AA</p>
          </item>
          <item eId="list0.BB">
            <num>(BB)</num>
            <p>item-BB</p>
          </item>
        </blockList>
XML
    ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="list0">
              <item eId="list0.y">
                <num>(y)</num>
                <p>foo</p>
              </item>
              <item eId="list0.z">
                <num>(z)</num>
                <blockList eId="list0.z__list_1">
                  <listIntroduction>item-z</listIntroduction>
                  <item eId="list0.z__list_1__item_AA">
                    <num>(AA)</num>
                    <p>item-AA</p>
                  </item>
                  <item eId="list0.z__list_1__item_BB">
                    <num>(BB)</num>
                    <p>item-BB</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle deeply nested lists' do
      doc = xml2doc(subsection(<<XML
        <blockList eId="list0" renest="true">
          <item eId="list0.a">
            <num>(a)</num>
            <p>foo</p>
          </item>
          <item eId="list0.b">
            <num>(b)</num>
            <p>item-b</p>
          </item>
          <item eId="list0.i">
            <num>(i)</num>
            <p>item-b-i</p>
          </item>
          <item eId="list0.aa">
            <num>(aa)</num>
            <p>item-i-aa</p>
          </item>
          <item eId="list0.bb">
            <num>(bb)</num>
            <p>item-i-bb</p>
          </item>
          <item eId="list0.ii">
            <num>(ii)</num>
            <p>item-b-ii</p>
          </item>
          <item eId="list0.c">
            <num>(c)</num>
            <p>item-c</p>
          </item>
          <item eId="list0.i">
            <num>(i)</num>
            <p>item-c-i</p>
          </item>
          <item eId="list0.ii">
            <num>(ii)</num>
            <p>item-c-ii</p>
          </item>
          <item eId="list0.iii">
            <num>(iii)</num>
            <p>item-c-iii</p>
          </item>
        </blockList>
XML
    ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="list0">
              <item eId="list0.a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item eId="list0.b">
                <num>(b)</num>
                <blockList eId="list0.b__list_1">
                  <listIntroduction>item-b</listIntroduction>
                  <item eId="list0.b__list_1__item_i">
                    <num>(i)</num>
                    <blockList eId="list0.b__list_1__item_i__list_1">
                      <listIntroduction>item-b-i</listIntroduction>
                      <item eId="list0.b__list_1__item_i__list_1__item_aa">
                        <num>(aa)</num>
                        <p>item-i-aa</p>
                      </item>
                      <item eId="list0.b__list_1__item_i__list_1__item_bb">
                        <num>(bb)</num>
                        <p>item-i-bb</p>
                      </item>
                    </blockList>
                  </item>
                  <item eId="list0.b__list_1__item_ii">
                    <num>(ii)</num>
                    <p>item-b-ii</p>
                  </item>
                </blockList>
              </item>
              <item eId="list0.c">
                <num>(c)</num>
                <blockList eId="list0.c__list_2">
                  <listIntroduction>item-c</listIntroduction>
                  <item eId="list0.c__list_2__item_i">
                    <num>(i)</num>
                    <p>item-c-i</p>
                  </item>
                  <item eId="list0.c__list_2__item_ii">
                    <num>(ii)</num>
                    <p>item-c-ii</p>
                  </item>
                  <item eId="list0.c__list_2__item_iii">
                    <num>(iii)</num>
                    <p>item-c-iii</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
        )
    end

    # -------------------------------------------------------------------------

    it 'should jump back up a level when finding (i) near (h)' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1" renest="true">
              <item eId="sec__10__subsec_1__list_1__item_h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <item eId="sec__10__subsec_1__list_1__item_h">
                <num>(h)</num>
                <blockList eId="sec__10__subsec_1__list_1__item_h__list_1">
                  <listIntroduction>foo</listIntroduction>
                  <item eId="sec__10__subsec_1__list_1__item_h__list_1__item_i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item eId="sec__10__subsec_1__list_1__item_h__list_1__item_ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                </blockList>
              </item>
              <item eId="sec__10__subsec_1__list_1__item_i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle dotted numbers correctly' do
      doc = xml2doc(subsection(<<XML
            <blockList eId="sec__9__item_subsection-2__list_3" renest="true">
              <item eId="sec__9__item_subsection-2__list_3__item_9-2-1">
                <num>9.2.1</num>
                <p>is incapable of trading because of an illness, provided that:</p>
              </item>
              <item eId="sec__9__item_subsection-2__list_3__item_9-2-1-1">
                <num>9.2.1.1</num>
                <p>proof from a medical practitioner is provided to the City which certifies that the permit-holder is unable to trade; and</p>
              </item>
              <item eId="sec__9__item_subsection-2__list_3__item_9-2-1-2">
                <num>9.2.1.2</num>
                <p>the dependent or assistant is only permitted to replace the permit-</p>
              </item>
            </blockList>
XML
      ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__9__item_subsection-2__list_3">
              <item eId="sec__9__item_subsection-2__list_3__item_9-2-1">
                <num>9.2.1</num>
                <blockList eId="sec__9__item_subsection-2__list_3__item_9-2-1__list_1">
                  <listIntroduction>is incapable of trading because of an illness, provided that:</listIntroduction>
                  <item eId="sec__9__item_subsection-2__list_3__item_9-2-1__list_1__item_9-2-1-1">
                    <num>9.2.1.1</num>
                    <p>proof from a medical practitioner is provided to the City which certifies that the permit-holder is unable to trade; and</p>
                  </item>
                  <item eId="sec__9__item_subsection-2__list_3__item_9-2-1__list_1__item_9-2-1-2">
                    <num>9.2.1.2</num>
                    <p>the dependent or assistant is only permitted to replace the permit-</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    it 'should handle p tags just before' do
      doc = xml2doc(subsection(<<XML
        <p>intro</p>
        <blockList eId="sec__10__subsec_1__list_1">
          <item eId="sec__10__subsec_1__list_1__item_a">
            <num>(a)</num>
            <p>foo</p>
          </item>
        </blockList>
XML
        ))

      subject.adjust_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList eId="sec__10__subsec_1__list_1">
              <listIntroduction>intro</listIntroduction>
              <item eId="sec__10__subsec_1__list_1__item_a">
                <num>(a)</num>
                <p>foo</p>
              </item>
            </blockList>
XML
      )
    end
  end
end