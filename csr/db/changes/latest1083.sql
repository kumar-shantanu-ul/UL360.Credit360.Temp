-- Please update version.sql too -- this keeps clean builds in sync
define version=1083
@update_header

create table csr.changed_calcs (
	app_sid number(10) not null,
	object_sid number(10) not null,
	primary key (app_sid, object_sid)
) organization index;
insert into csr.changed_calcs 
select app_sid, object_sid 
from csr.audit_log where description ='Calculation changed'
and app_sid is not null and object_sid is not null
group by app_sid, object_sid;
commit;

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
  <xsl:template match="test">
    <xsl:element name="test-old">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>'))
 where i.calc_xml is not null
   and i.ind_type in (1,2)
   and (i.app_sid, i.ind_sid) not in (
   		select app_sid, object_sid
		  from csr.changed_calcs);
		  
drop table csr.changed_calcs;

@../indicator_body

@update_tail
