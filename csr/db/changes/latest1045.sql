-- Please update version.sql too -- this keeps clean builds in sync
define version=1045
@update_header

update csr.ind i
   set calc_xml = xmltransform(i.calc_xml, xmltype('<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Identity transformation -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <!-- Identity transformation overridden for element b -->
  <xsl:template match="add">
    <xsl:element name="add-old">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="subtract">
    <xsl:element name="subtract-old">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="multiply">
    <xsl:element name="multiply-old">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="divide">
    <xsl:element name="divide-old">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>'))
 where i.calc_xml is not null;

@../indicator_body

@update_tail
