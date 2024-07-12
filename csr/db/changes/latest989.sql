-- Please update version.sql too -- this keeps clean builds in sync
define version=989
@update_header

set serveroutput on;

CREATE TABLE CSR.XXBackupCalcs (
	ind_sid NUMBER(10),
	calc_xml XMLTYPE
);

CREATE OR REPLACE PROCEDURE CSR.CleanCalcXml(
	in_node							IN	dbms_xmldom.domnode
)
AS
	v_node							dbms_xmldom.domnode := in_node;
	v_child							dbms_xmldom.domnode;	
	v_sid 							varchar2(100);
	v_des 							varchar2(2000);
	v_allowed						NUMBER(1);
	v_name							varchar2(1000);
BEGIN
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			-- check for nodes which are allowed to have sids
			v_name := dbms_xmldom.getnodename(v_node);
			
			SELECT count(*)
			  INTO v_allowed
			  FROM DUAL
			 WHERE v_name IN (
				'sum',
				'average', 
				'min',
				'max',
				'path',
				'ytd',
				'fye',
				'rollingyear',
				'previousperiod',
				'periodpreviousyear',
				'percentchange',
				'periodpreviousnyears',
				'rollingperiod',
				'npv',
				'pv',
				'model',
				'modelrun'
			 );
			 
			-- we need to delete the sid attribute if it exists
			IF v_allowed = 0 THEN
				v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'sid');
				
				IF v_sid IS NOT NULL THEN
					dbms_xmldom.removeattribute(dbms_xmldom.makeelement(v_node), 'sid');					
				END IF;

				v_des := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'description');			
				IF v_des IS NOT NULL THEN
					dbms_xmldom.removeattribute(dbms_xmldom.makeelement(v_node), 'description');
				END IF;
			END IF;

			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
				CleanCalcXml(v_child);
			END IF;
		END IF;
		
		v_node := dbms_xmldom.getnextsibling(v_node);
	END LOOP;
END;
/

DECLARE
	v_doc							dbms_xmldom.domdocument;
	v_xml							sys.xmltype;
	v_count							number(10);
BEGIN
	dbms_output.enable();
	
	v_count:= 0;
	
	FOR r IN (
		SELECT ind_sid, calc_xml
		  FROM csr.ind
		 WHERE calc_xml IS NOT NULL
	) LOOP
		v_doc := dbms_xmldom.newdomdocument(r.calc_xml);
		
		-- Create a backup
		INSERT INTO csr.XXBackupCalcs (ind_sid, calc_xml) VALUES (r.ind_sid, r.calc_xml);
		
		-- Recursively clean the XML
		csr.CleanCalcXml(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc)));
		
		v_xml := dbms_xmldom.getxmltype(v_doc);
		
		UPDATE csr.ind
		   SET calc_xml = v_xml
		 WHERE ind_sid = r.ind_sid;
		 
		 v_count := v_count + 1;		 
	END LOOP;
	
	dbms_output.put_line('Processed: '||v_count);
	
	COMMIT;
END;
/

DROP PROCEDURE CSR.CleanCalcXml;

@update_tail