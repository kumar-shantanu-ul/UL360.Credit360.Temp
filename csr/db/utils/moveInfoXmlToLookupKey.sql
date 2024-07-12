begin
   user_pkg.logonadmin('linde.credit360.com');
   for r in (
           select *
             from (
                   select region_sid, TRIM(REGEXP_REPLACE(EXTRACT(info_xml, 'fields/field[@name="dcu"]/text()').getStringVal(),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n')) n
                   from region
             )
             where n is not null
   )
   loop
           update region set lookup_key = r.n where region_sid = r.region_sid;
   end loop;
end;
/



create or replace function remove_node(xmldoc xmltype, xpath varchar2)
return xmltype
as
  DOC       DBMS_XMLDOM.DOMDocument;
  NODE_LIST DBMS_XMLDOM.DOMNodeList;
  NODE      DBMS_XMLDOM.DOMNode;
  PARENT    DBMS_XMLDOM.DOMNode;
begin
  DOC := DBMS_XMLDOM.NEWDOMDOCUMENT(xmldoc);
  NODE_LIST := DBMS_XSLPROCESSOR.SELECTNODES(DBMS_XMLDOM.MAKENODE(DOC),XPATH);
  IF DBMS_XMLDOM.GETLENGTH(NODE_LIST) > 0 THEN
    for i in 1..DBMS_XMLDOM.GETLENGTH(NODE_LIST) loop
      NODE := DBMS_XMLDOM.ITEM(NODE_LIST,i-1);
      PARENT := DBMS_XMLDOM.GETPARENTNODE(NODE);
      PARENT := DBMS_XMLDOM.REMOVECHILD(PARENT,NODE);
    end loop;
  end if;
  return XMLDOC;
end;
/ 

update region set info_xml = remove_node(info_xml, '//field[@name="dcu"]');
update customer set region_info_xml_fields = remove_node(info_xml, '//field[@name="dcu"]');

drop function remove_node;
