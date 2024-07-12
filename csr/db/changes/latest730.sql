-- Please update version.sql too -- this keeps clean builds in sync
define version=730
@update_header

declare
	v_doc							dbms_xmldom.domdocument;
	v_nodes							dbms_xmldom.domnodelist;
	v_node							dbms_xmldom.domelement;
	v_ind_node						dbms_xmldom.domelement;
	v_dummy							dbms_xmldom.domnode;
	v_xml							xmltype;
	v_lookup_key					ind.lookup_key%type;
begin
	for r in (select app_sid, ind_sid, aggregation_xml from csr.delegation_grid where aggregation_xml is not null) loop
		-- Find the indicators involved in aggregation
		v_doc := dbms_xmldom.newdomdocument(r.aggregation_xml);
		v_nodes := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc), '/cms:aggregates/cms:aggregate/cms:map/cms:column', 'xmlns:cms=http://www.credit360.com/XMLSchemas/cms');
		
		FOR i IN 0 .. dbms_xmldom.getLength(v_nodes) - 1 LOOP
			v_node := dbms_xmldom.makeElement(dbms_xmldom.item(v_nodes, i));
			v_lookup_key := dbms_xmldom.getAttribute(v_node, 'lookup-key');
			IF v_lookup_key IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing lookup-key attribute for ind with sid '||r.ind_sid);
			END IF;
			dbms_xmldom.removeAttribute(v_node, 'lookup-key');
			v_ind_node := dbms_xmldom.createElement(v_doc, 'indicator');
			dbms_xmldom.setAttribute(v_ind_node, 'lookup-key', v_lookup_key);
			v_dummy := dbms_xmldom.appendChild(dbms_xmldom.makeNode(v_node), dbms_xmldom.makeNode(v_ind_node));
		END LOOP;
		
		v_xml := dbms_xmldom.getxmltype(v_doc);
		
		update csr.delegation_grid
		   set aggregation_xml = v_xml
		 where app_sid = r.app_sid and ind_sid = r.ind_sid;
		
	end loop;
end;
/

@../delegation_body
	 
@update_tail