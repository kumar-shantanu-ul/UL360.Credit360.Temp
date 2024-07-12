-- Please update version.sql too -- this keeps clean builds in sync
define version=710
@update_header

CREATE SEQUENCE csr.QS_ANSWER_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QS_QUESTION_OPTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;



CREATE TABLE csr.QS_ANSWER_FILE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_ANSWER_FILE_ID     NUMBER(10, 0)    NOT NULL,
    SURVEY_RESPONSE_ID    NUMBER(10, 0)    NOT NULL,
    QUESTION_ID           NUMBER(10, 0)    NOT NULL,
    FILENAME              VARCHAR2(255)    NOT NULL,
    MIME_TYPE             VARCHAR2(256)    NOT NULL,
    DATA                  BLOB             NOT NULL,
    SHA1                  RAW(20)          NOT NULL,
    UPLOADED_DTM          DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_QS_ANSWER_FILE PRIMARY KEY (APP_SID, QS_ANSWER_FILE_ID)
);

DROP TABLE csr.QS_ANSWER_FILE_UPLOAD PURGE;

CREATE TABLE csr.QS_QUESTION_OPTION(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QUESTION_OPTION_ID    NUMBER(10, 0)     NOT NULL,
    QUESTION_ID           NUMBER(10, 0)     NOT NULL,
    POS                   NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    LABEL                 VARCHAR2(4000)    NOT NULL,
    IS_VISIBLE            NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    SCORE                 NUMBER(10, 0),
    COLOR                 NUMBER(10, 0),
    CONSTRAINT CHK_QS_QUES_OPT_VIS CHECK (IS_VISIBLE IN (0,1)),
    CONSTRAINT PK_QS_QUESTION_OPTION PRIMARY KEY (APP_SID, QUESTION_OPTION_ID)
);

CREATE TABLE csr.QS_QUESTION_TYPE(
    QUESTION_TYPE    VARCHAR2(20)     NOT NULL,
    LABEL            VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_QS_QUESTION_TYPE PRIMARY KEY (QUESTION_TYPE)
);

ALTER TABLE csr.QUICK_SURVEY DROP COLUMN QUESTION_XML_PATH;

ALTER TABLE csr.QUICK_SURVEY_ANSWER DROP COLUMN QUESTION_CODE;

ALTER TABLE csr.QUICK_SURVEY_ANSWER ADD (
	SCORE	NUMBER(10,0)
);
 
ALTER TABLE csr.QUICK_SURVEY_QUESTION ADD (
    PARENT_ID    	 NUMBER(10, 0),
    QUESTION_TYPE    VARCHAR2(20),
    SCORE            NUMBER(10, 0),
    LOOKUP_KEY       VARCHAR2(255)
);

ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD (
    COMPANY_SID    NUMBER(10, 0)
);

ALTER TABLE csr.QUICK_SURVEY_QUESTION ADD CONSTRAINT FK_QS_QUES_PARENT_QUES 
    FOREIGN KEY (APP_SID, PARENT_ID)
    REFERENCES csr.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID)
;

CREATE UNIQUE INDEX csr.UK_QUESTION_AND_OPTION ON csr.QS_QUESTION_OPTION(QUESTION_ID, QUESTION_OPTION_ID);

ALTER TABLE csr.QS_ANSWER_FILE ADD CONSTRAINT RefCUSTOMER2192 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID);

ALTER TABLE csr.QS_ANSWER_FILE ADD CONSTRAINT RefQUICK_SURVEY_ANSWER2193 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID)
    REFERENCES csr.QUICK_SURVEY_ANSWER(APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID);


ALTER TABLE csr.QS_QUESTION_OPTION ADD CONSTRAINT RefCUSTOMER2194 
     FOREIGN KEY (APP_SID)
     REFERENCES csr.CUSTOMER(APP_SID)
 ;
 
ALTER TABLE csr.QS_QUESTION_OPTION ADD CONSTRAINT RefQUICK_SURVEY_QUESTION2195 
    FOREIGN KEY (APP_SID, QUESTION_ID)
    REFERENCES csr.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID)
 ;
 
ALTER TABLE csr.QUICK_SURVEY_QUESTION ADD CONSTRAINT RefQS_QUESTION_TYPE2196 
    FOREIGN KEY (QUESTION_TYPE)
    REFERENCES csr.QS_QUESTION_TYPE(QUESTION_TYPE);
 
BEGIN
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('section', 'Section');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('radio', 'Question - radio buttons');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('checkboxgroup', 'Question - checkbox group');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('checkbox', 'Question - checkbox item');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('note', 'Question - text');
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('pagebreak', 'Page break');
END;
/

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_ROW AS
	OBJECT (
		QUESTION_ID		NUMBER(10),
		PARENT_ID		NUMBER(10),
		POS				NUMBER(10), 
		LABEL			VARCHAR2(4000), 
		QUESTION_TYPE	VARCHAR2(40), 
		SCORE			NUMBER(10)
	);
/
CREATE OR REPLACE TYPE csr.T_QS_QUESTION_TABLE AS
  TABLE OF csr.T_QS_QUESTION_ROW;
/

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_OPTION_ROW AS
	OBJECT (
		QUESTION_ID			NUMBER(10), 
		QUESTION_OPTION_ID	NUMBER(10), 
		POS					NUMBER(10), 		
		LABEL				VARCHAR2(4000), 
		SCORE				NUMBER(10), 
		COLOR				NUMBER(10)
	);
/
CREATE OR REPLACE TYPE csr.T_QS_QUESTION_OPTION_TABLE AS
  TABLE OF csr.T_QS_QUESTION_OPTION_ROW;
/

-- yikes... lots of code just to set some attributes!
DECLARE
	v_clob		CLOB;
	v_parser	dbms_xmlparser.Parser;
	v_doc		DBMS_XMLDOM.DOMDocument;
	v_nl		DBMS_XMLDOM.DOMNodeList;
	v_n			DBMS_XMLDOM.DOMNode;
	v_id		VARCHAR2(255);
	v_final	 	CLOB;
	t_q			T_QS_QUESTION_TABLE;
	t_qo		T_QS_QUESTION_OPTION_TABLE;
BEGIN
	-- Create a parser.
	v_parser := dbms_xmlparser.newParser;

    FOR r IN (
        SELECT host, survey_sid 
          FROM csr.quick_survey qs 
            JOIN csr.customer c ON qs.app_sid = c.app_sid
         WHERE question_xml IS NOT NULL
    )
    LOOP
        dbms_output.put_line('doing '||r.host||', survey sid '||r.survey_sid||'...');
        user_pkg.logonadmin(r.host);
        SELECT EXTRACT(question_xml,'/').getClobVal()
         INTO v_clob
         FROM csr.quick_survey 
        WHERE survey_sid =r.survey_sid;
        -- Parse the document and create a new DOM document.
        dbms_xmlparser.parseClob(v_parser, v_clob);
        v_doc := dbms_xmlparser.getDocument(v_parser);
    
        -- Free resources associated with the clob now they are no longer needed.
        dbms_lob.freetemporary(v_clob);
    
        -- Get a list of all the nodes in the document
        v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//option');    
        FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
            v_n := DBMS_XMLDOM.item(v_nl, idx);
            SELECT csr.qs_question_option_id_seq.nextval
              INTO v_id
              FROM dual;
            DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id', v_id);
        END LOOP;
        
        -- fix up duff ids
        --v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//*[@id="0" or string-length(translate(@id,"0123456789",""))!=0]');
        -- on live it seems best just to redo all ids
        v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//*[@id]');
        FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
            v_n := DBMS_XMLDOM.item(v_nl, idx);
            SELECT csr.question_id_seq.nextval
              INTO v_id
              FROM dual;
            DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id', v_id);
        END LOOP;
    
        -- fix up 
        v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//*[@type="dropdown"]');
        FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
            v_n := DBMS_XMLDOM.item(v_nl, idx);
            DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'type', 'radio');
        END LOOP;
    
        --write back
        DBMS_LOB.CreateTemporary(v_final, TRUE);
        DBMS_XMLDOM.WriteToClob(DBMS_XMLDOM.makeNode(v_doc), v_final);
        
        UPDATE csr.quick_survey 
           SET question_xml = XMLTYPE(v_final)
        WHERE survey_sid = r.survey_sid;
        
        -- Free any resources associated with the document now it
        -- is no longer needed.
        DBMS_LOB.FreeTemporary(v_final);
        DBMS_XMLDOM.FreeDocument(v_doc);
        
        
        
		-- UPDATE QUESTION DATA
		-- XMLTABLE documentation isn't great. I found this article useful:
		--   https://forums.oracle.com/forums/thread.jspa?threadID=2175225 amp tstart=0#9363408
		SELECT T_QS_QUESTION_ROW(xt.id, xt.parent_id, xt.pos, xt.description,
			case when xt.name = 'question' then lower(xt.question_type)
				else lower(name)
			end,
			xt.score)
			BULK COLLECT INTO t_q
		  FROM csr.quick_survey, 
			XMLTABLE(
				'for $i in //section|//question|//pageBreak
				 return <r id="{$i/@id}" parent-id="{$i/../@id}" type="{$i/@type}" score="{$i/@score}" name="{name($i)}"><description>{$i/description}</description></r>'
			PASSING question_xml
			COLUMNS
				pos              FOR ORDINALITY,
				id               NUMBER(10) PATH '@id',
				parent_id        NUMBER(10) PATH '@parent-id',
				question_type    VARCHAR2(255) PATH '@type',
				description      VARCHAR2(4000) PATH 'description',
				score            NUMBER(10) PATH '@score',
				name             VARCHAR2(255) PATH '@name'
			)xt
		 WHERE survey_sid = r.survey_sid
		;

		-- hide if no longer in XML
		UPDATE csr.quick_survey_question
		   SET is_visible = 0
		 WHERE survey_sid = r.survey_sid
		   AND question_id NOT IN (
				SELECT question_id FROM TABLE(t_q)	   
		   );
		
		-- update if in our table already
		UPDATE csr.quick_survey_question
		   SET (parent_id, label, pos, question_type, score) = (
				 SELECT x.parent_id, x.label, x.pos, x.question_type, x.score
				   FROM TABLE(t_q)x
				  WHERE quick_survey_question.question_id = x.question_id
			)
		 WHERE survey_sid = r.survey_sid
		   AND EXISTS (SELECT null FROM TABLE(t_q)x WHERE x.question_id = quick_survey_question.question_id);
		
		-- insert if new
		INSERT INTO csr.quick_survey_question 
			(question_id, parent_id, survey_sid, pos, is_visible, label, question_type, score)
			SELECT question_id, parent_id, r.survey_sid, pos, 1, label, question_type, score
			  FROM TABLE(t_q)
			 WHERE question_id NOT IN (
				SELECT question_id 
				  FROM csr.quick_survey_question 
				 WHERE survey_sid = r.survey_sid
			 );
			 
			 
			 
		-- UPDATE QUESTION OPTION DATA
		SELECT T_QS_QUESTION_OPTION_ROW(xt.question_id, xt.question_option_id, xt.pos, xt.description, xt.score, xt.color)
		  BULK COLLECT INTO t_qo
		  FROM csr.quick_survey, 
			XMLTABLE(
				'for $i in //question[@id]/option
				 return <r id="{$i/../@id}" option-id="{$i/@id}" score="{$i/@score}" color="{$i/@color}">{$i/text()}</r>'
			PASSING question_xml
			COLUMNS
				pos              	FOR ORDINALITY,
				question_id      	NUMBER(10) PATH '@id',
				question_option_id  NUMBER(10) PATH '@option-id',
				score            	NUMBER(10) PATH '@score',
				color            	NUMBER(10) PATH '@color',
				description      	VARCHAR2(4000) PATH '.'
			)xt
		 WHERE survey_sid = r.survey_sid;

		-- hide if no longer in XML
		UPDATE csr.qs_question_option
		   SET is_visible = 0
		 WHERE question_option_id IN (
				SELECT question_option_Id 
				  FROM csr.quick_survey_question q 
					JOIN csr.qs_question_option qo ON q.question_id = qo.question_id
				 WHERE q.survey_sid = r.survey_sid
				   AND qo.is_visible = 1
				  MINUS
				SELECT question_option_id FROM TABLE(t_qo)
		   );
		
		-- update if in our table already
		UPDATE csr.qs_question_option
		   SET (label, pos, color, score) = (
				 SELECT x.label, x.pos, x.color, x.score
				   FROM TABLE(t_qo)x
				  WHERE qs_question_option.question_option_id = x.question_option_id
			)
		 WHERE question_option_id IN (
				SELECT question_option_id FROM TABLE(t_qo)
		  );
		
		-- insert if new
		INSERT INTO csr.qs_question_option
			(question_id, question_option_id, pos, is_visible, label, score, color)
			SELECT question_id, question_option_id, pos, 1, nvl(label,'unspecified'), score, color
			  FROM TABLE(t_qo)
			 WHERE question_option_id NOT IN (			
				SELECT question_option_Id 
				  FROM quick_survey_question q 
					JOIN qs_question_option qo ON q.question_id = qo.question_id
				 WHERE q.survey_sid = r.survey_sid
			 );
			 
		
        
        user_pkg.logonadmin();
    END LOOP;
    
    dbms_xmlparser.freeParser(v_parser);
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_xmlparser.freeParser(v_parser);
		DBMS_XMLDOM.freeDocument(v_doc);
		RAISE;	
END;
/

-- stuff that's been deleted so we no longer know about it
update csr.quick_survey_question set question_type = 'section' where question_type is null and is_visible = 0;

update csr.quick_survey_question set question_type = 'section' where question_type is null and survey_sid in (
	select survey_sid from quick_survey where question_xml is null
);

ALTER TABLE csr.QUICK_SURVEY_QUESTION MODIFY QUESTION_TYPE NOT NULL;

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
