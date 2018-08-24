<?xml version="1.0"?>

<!-- ############################## -->
<!-- I DON'T THINK WE USE THIS FILE -->
<!-- ############################## -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:a="http://www.akomantoso.org/2.0"
  exclude-result-prefixes="a">

  <xsl:output method="text" indent="no" omit-xml-declaration="yes" />
  <xsl:strip-space elements="*"/>

  <!-- adds a backslash to the start of the value param, if necessary -->
  <xsl:template name="escape">
    <xsl:param name="value"/>

    <xsl:variable name="prefix" select="translate(substring($value, 1, 10), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    <xsl:variable name="numprefix" select="translate(translate(substring($prefix, 1, 3), '1234567890', 'NNNNNNNNNN'), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'NNNNNNNNNNNNNNNNNNNNNNNNNN')" />

    <!-- p tags must escape initial content that looks like a block element marker.
         Note that the two hyphens are different characters. -->
    <xsl:if test="$prefix = 'BODY' or
                  $prefix = 'PREAMBLE' or
                  $prefix = 'PREFACE' or
                  starts-with($prefix, 'KSI') or
                  starts-with($prefix, 'TYTU') or
                  starts-with($prefix, 'ROZDZIA') or
                  starts-with($prefix, 'DZIA') or
                  starts-with($prefix, 'ODDZIA') or
                  starts-with($prefix, 'ART.') or
                  starts-with($prefix, '§') or
                  starts-with($prefix, 'SCHEDULE ') or
                  starts-with($prefix, '{|') or
                  starts-with($numprefix, 'N)') or
                  starts-with($numprefix, 'NN)') or
                  starts-with($numprefix, 'N.') or
                  starts-with($numprefix, 'NN.')">
      <xsl:text>\</xsl:text>
    </xsl:if>
    <xsl:value-of select="$value"/>
  </xsl:template>


  
  <!-- ################ -->
  <!-- MAJOR CONTAINERS -->
  <!-- ################ -->

  <xsl:template match="a:act">
    <xsl:apply-templates select="a:coverPage" />
    <xsl:apply-templates select="a:preface" />
    <xsl:apply-templates select="a:preamble" />
    <xsl:apply-templates select="a:body" />
    <xsl:apply-templates select="a:conclusions" />
  </xsl:template>

  <xsl:template match="a:preface">
    <xsl:text>PREFACE</xsl:text>
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="a:preamble">
    <xsl:text>PREAMBLE</xsl:text>
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="a:book">
    <xsl:text>KSIĘGA </xsl:text>
    <xsl:value-of select="./a:num" />
    <xsl:text> - </xsl:text>
    <xsl:value-of select="./a:heading" />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num) and not(self::a:heading)]" />
  </xsl:template>

  <xsl:template match="a:title">
    <xsl:text>TYTUŁ </xsl:text>
    <xsl:value-of select="./a:num" />
    <xsl:text> - </xsl:text>
    <xsl:value-of select="./a:heading" />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num) and not(self::a:heading)]" />
  </xsl:template>

  <xsl:template match="a:division">
    <xsl:text>Dział </xsl:text>
    <xsl:value-of select="./a:num" />
    <xsl:text> - </xsl:text>
    <xsl:value-of select="./a:heading" />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num) and not(self::a:heading)]" />
  </xsl:template>

  <xsl:template match="a:chapter">
    <xsl:text>Rozdział </xsl:text>
    <xsl:value-of select="./a:num" />
    <xsl:text> - </xsl:text>
    <xsl:value-of select="./a:heading" />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num) and not(self::a:heading)]" />
  </xsl:template>

  <xsl:template match="a:subdivision">
    <xsl:text>Oddział </xsl:text>
    <xsl:value-of select="./a:num" />
    <xsl:text> - </xsl:text>
    <xsl:value-of select="./a:heading" />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num) and not(self::a:heading)]" />
  </xsl:template>

  <xsl:template match="a:section[@refersTo='statute']">
    <xsl:text>Art. </xsl:text>
    <xsl:value-of select="a:num" />
    <xsl:text>.</xsl:text>
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:section[@refersTo='ordinance']">
    <xsl:text>§</xsl:text>
    <xsl:value-of select="a:num" />
    <xsl:text>.</xsl:text>
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:subsection[@refersTo='noncode_level1_unit']">
    <xsl:if test="a:num != ''">
      <xsl:value-of select="a:num" />
      <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:subsection[@refersTo='code_level1_unit']">
    <xsl:text>§</xsl:text>
    <xsl:value-of select="a:num" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:list">
    <xsl:if test="a:intro != ''">
      <xsl:value-of select="a:intro" />
      <xsl:call-template name="newline"/>
      <xsl:call-template name="newline"/>
    </xsl:if>
    <xsl:apply-templates select="./*[not(self::a:intro)]" />
  </xsl:template>

  <xsl:template match="a:item | a:point">
    <xsl:value-of select="./a:num" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:wrapUp[@refersTo='wrap_up_for_points']">
    <xsl:text>@@INDENT0@@</xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:wrapUp[@refersTo='wrap_up_for_letters']">
    <xsl:text>@@INDENT1@@</xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:indent[@refersTo='single_tiret']">
    <xsl:value-of select="a:num" />
    <xsl:text>@@INDENT2@@– </xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:indent[@refersTo='double_tiret']">
    <xsl:value-of select="a:num" />
    <xsl:text>@@INDENT3@@– – </xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>

  <xsl:template match="a:indent[@refersTo='triple_tiret']">
    <xsl:value-of select="a:num" />
    <xsl:text>@@INDENT4@@– – – </xsl:text>
    <xsl:apply-templates select="./*[not(self::a:num)]" />
  </xsl:template>



  <!-- ############ -->
  <!-- OTHER THINGS -->
  <!-- ############ -->

  <!-- these are block elements and have a newline at the end -->
  <xsl:template match="a:heading">
    <xsl:apply-templates />
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
  </xsl:template>

  <xsl:template match="a:p">
    <xsl:apply-templates/>
    <!-- p tags must end with a newline -->
    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
  </xsl:template>

  <!-- first text nodes of these elems must be escaped if they have special chars -->
  <xsl:template match="a:p[not(ancestor::a:table)]/text()[1] | a:intro/text()[1]">
    <xsl:call-template name="escape">
      <xsl:with-param name="value" select="." />
    </xsl:call-template>
  </xsl:template>

  <!-- components/schedules -->
  <xsl:template match="a:doc">
    <xsl:text>Schedule - </xsl:text>
    <xsl:value-of select="a:meta/a:identification/a:FRBRWork/a:FRBRalias/@value" />

    <xsl:if test="a:mainBody/a:article/a:heading">
      <xsl:call-template name="newline"/>
      <xsl:value-of select="a:mainBody/a:article/a:heading" />
    </xsl:if>

    <xsl:call-template name="newline"/>
    <xsl:call-template name="newline"/>
    <xsl:apply-templates select="a:mainBody" />
  </xsl:template>

  <xsl:template match="a:mainBody/a:article/a:heading">
    <!-- no-op, this is handled by the schedules template above -->
  </xsl:template>

  <!-- tables -->
  <xsl:template match="a:table">
    <xsl:text>{| </xsl:text>

    <!-- attributes -->
    <xsl:for-each select="@*[local-name()!='id']">
      <xsl:value-of select="local-name(.)" />
      <xsl:text>="</xsl:text>
      <xsl:value-of select="." />
      <xsl:text>" </xsl:text>
    </xsl:for-each>
    <xsl:text>
|-</xsl:text>

    <xsl:apply-templates />
    <xsl:text>
|}

</xsl:text>
  </xsl:template>

  <xsl:template match="a:tr">
    <xsl:apply-templates />
    <xsl:text>
|-</xsl:text>
  </xsl:template>

  <xsl:template match="a:th|a:td">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'th'">
        <xsl:text>
! </xsl:text>
      </xsl:when>
      <xsl:when test="local-name(.) = 'td'">
        <xsl:text>
| </xsl:text>
      </xsl:when>
    </xsl:choose>

    <!-- attributes -->
    <xsl:if test="@*">
      <xsl:for-each select="@*">
        <xsl:value-of select="local-name(.)" />
        <xsl:text>="</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>" </xsl:text>
      </xsl:for-each>
      <xsl:text>| </xsl:text>
    </xsl:if>

    <xsl:apply-templates />
  </xsl:template>

  <!-- don't end p tags with newlines in tables -->
  <xsl:template match="a:table//a:p">
    <xsl:apply-templates />
  </xsl:template>

  <!-- END tables -->

  <xsl:template match="a:remark">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates />
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="a:ref">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates />
    <xsl:text>](</xsl:text>
    <xsl:value-of select="@href" />
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="a:img">
    <xsl:text>![</xsl:text>
    <xsl:value-of select="@alt" />
    <xsl:text>](</xsl:text>
    <xsl:value-of select="@src" />
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="a:eol">
    <xsl:call-template name="newline"/>
  </xsl:template>


  <!-- for most nodes, just dump their text content -->
  <xsl:template match="*">
    <xsl:text/><xsl:apply-templates /><xsl:text/>
  </xsl:template>

  <!-- Helper template to avoid unindented </xsl:text> tags, making the file hard to read. -->
  <xsl:template name="newline">
    <xsl:text>
</xsl:text>
  </xsl:template>

</xsl:stylesheet>
