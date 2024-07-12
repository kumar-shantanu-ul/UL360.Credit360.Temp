clear break
clear comp
clear col

set pagesize 0
set linesize 9999
set trimspool on
set tab off
set echo off
set feedback off
set recsep off

ACCEPT host CHAR PROMPT 'Host: ' 
ACCEPT surveySid CHAR PROMPT 'Survey Sid: ' 
PROMPT "Writing to \temp\q.xml"
spool \temp\q.xml

-- strip IDs
DECLARE
	in_survey_sid	security_pkg.T_SID_ID;
	v_clob			CLOB;
	v_parser		dbms_xmlparser.Parser;
	v_doc			DBMS_XMLDOM.DOMDocument;
	v_nl			DBMS_XMLDOM.DOMNodeList;
	v_n				DBMS_XMLDOM.DOMNode;
	v_final	 		CLOB;
 	v_offset 		NUMBER := 1;
 	v_inc			NUMBER;
 	v_s				VARCHAR2(4000);
BEGIN
	-- Create a parser.
	v_parser := dbms_xmlparser.newParser;

	user_pkg.logonadmin('&&host');

	SELECT EXTRACT(question_xml,'/').getClobVal()
	 INTO v_clob
	 FROM quick_survey 
	WHERE survey_sid = &&surveySid;
	
	-- Parse the document and create a new DOM document.
	dbms_xmlparser.parseClob(v_parser, v_clob);
	v_doc := dbms_xmlparser.getDocument(v_parser);

	-- Free resources associated with the clob now they are no longer needed.
	dbms_lob.freetemporary(v_clob);

	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//*[@id]');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);
		DBMS_XMLDOM.REMOVEATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');
	END LOOP;

	--write back
	DBMS_LOB.CreateTemporary(v_final, TRUE);
	DBMS_XMLDOM.WriteToClob(DBMS_XMLDOM.makeNode(v_doc), v_final);
	
	LOOP 
		EXIT WHEN v_offset > DBMS_LOB.GETLENGTH(v_final);
		v_s := DBMS_LOB.SUBSTR( v_final, 3000, v_offset);
		v_inc := INSTR(v_s, '>', -1);
		IF v_inc = 0 THEN
			v_inc := 3000;
		END IF;
		DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR( v_final, v_inc, v_offset));
		v_offset := v_offset + v_inc;
  	END LOOP;
	
	-- Free any resources associated with the document now it
	-- is no longer needed.
	DBMS_LOB.FreeTemporary(v_final);
	DBMS_XMLDOM.FreeDocument(v_doc);
    
    dbms_xmlparser.freeParser(v_parser);
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_xmlparser.freeParser(v_parser);
		DBMS_XMLDOM.freeDocument(v_doc);
		RAISE;	
END;
/

spool off

exit
