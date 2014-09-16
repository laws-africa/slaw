<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:a="http://www.akomantoso.org/2.0"
  exclude-result-prefixes="a">

  <xsl:import href="elements.xsl" />

  <xsl:output method="html" />

  <xsl:template match="/">
    <!-- root_elem is passed in as an xpath parameter -->
    <xsl:apply-templates select="$root_elem" />
  </xsl:template>
  
</xsl:stylesheet> 

