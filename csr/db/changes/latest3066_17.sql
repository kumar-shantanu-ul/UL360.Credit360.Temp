-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_QUESTION_XML
(
	ID			NUMBER(10)		NOT NULL,
	XML			CLOB			NOT NULL,
	CONSTRAINT PK_TEMP_QUESTION_XML PRIMARY KEY (ID)
)
ON COMMIT DELETE ROWS
;

-- Alter tables
ALTER TABLE CSR.QUESTION_VERSION ADD (
	QUESTION_XML			CLOB NULL
);

ALTER TABLE CSR.QUESTION_OPTION ADD (
	QUESTION_OPTION_XML		CLOB NULL
);

ALTER TABLE CSR.TEMPOR_QUESTION ADD (
	QUESTION_XML			CLOB
);

ALTER TABLE CSR.TEMP_QUESTION_OPTION ADD (
	QUESTION_OPTION_XML		CLOB
);

ALTER TABLE CSRIMP.QUESTION_VERSION ADD (
	QUESTION_XML			CLOB NOT NULL
);

ALTER TABLE CSRIMP.QUESTION_OPTION ADD (
	QUESTION_OPTION_XML		CLOB NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$question AS
	SELECT qv.app_sid, qv.question_id, qv.question_version, qv.question_draft, qv.parent_id, qv.parent_version, qv.parent_draft, qv.label, qv.pos, qv.score, qv.max_score, qv.upload_score,
		qv.weight, qv.dont_normalise_score, qv.has_score_expression, qv.has_max_score_expr, qv.remember_answer, qv.count_question, qv.action,
		q.owned_by_survey_sid, q.question_type, q.custom_question_type_id, q.lookup_key, q.maps_to_ind_sid, q.measure_sid
	  FROM csr.question_version qv
	  JOIN csr.question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;


-- *** Data changes ***
-- RLS

-- Data
DECLARE
    v_doc					DBMS_XMLDOM.DOMDocument;
	PROCEDURE ExtractQuestionXML(
		in_app_sid				IN	csr.quick_survey_version.app_sid%TYPE,
		in_doc					IN	DBMS_XMLDOM.DOMDocument,
		in_version		        IN	csr.quick_survey_version.survey_version%TYPE
	)
	AS
		v_question_id			csr.question.question_id%TYPE;
		v_nl					DBMS_XMLDOM.DOMNodeList;
		v_n						DBMS_XMLDOM.DOMNode;
		v_q						CLOB;
		v_e						DBMS_XMLDOM.DOMElement;

		v_cnl					DBMS_XMLDOM.DOMNodeList;
		v_cn					DBMS_XMLDOM.DOMNode;
		v_null					DBMS_XMLDOM.DOMNode;

        v_count                 NUMBER;
	BEGIN
		v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(in_doc),'//question|//pageBreak|//section|//checkbox|//radioRow');
		FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
			v_n := DBMS_XMLDOM.item(v_nl, idx);

			v_cnl := dbms_xslprocessor.selectNodes(v_n,'question|pageBreak|section|checkbox|radioRow|option');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_cnl) - 1 LOOP
				v_cn := DBMS_XMLDOM.item(v_cnl, idx2);
				v_null := DBMS_XMLDOM.removeChild(v_n, v_cn);
			END LOOP;

			v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');

			DBMS_LOB.CreateTemporary(v_q, TRUE);
			DBMS_XMLDOM.writeToClob(v_n, v_q);

			UPDATE csr.question_version
			   SET question_xml = v_q
			 WHERE question_id = v_question_id
			   AND question_version = in_version
			   AND app_sid = in_app_sid;

            v_count := SQL%ROWCOUNT;

            IF v_count = 0 THEN
                dbms_output.put_line('question_id = ' || v_question_id || ', version = ' || in_version);
            END IF;

			DBMS_LOB.FreeTemporary(v_q);
		END LOOP;
	END ExtractQuestionXML;

	PROCEDURE ExtractQuestionOptionXML(
		in_app_sid				IN	csr.quick_survey_version.app_sid%TYPE,
		in_doc					IN	DBMS_XMLDOM.DOMDocument,
		in_version		        IN	csr.quick_survey_version.survey_version%TYPE
	)
	AS
		v_qopt_id				csr.question_option.question_option_id%TYPE;
		v_question_id			csr.question.question_id%TYPE;
		v_nl					DBMS_XMLDOM.DOMNodeList;
		v_n						DBMS_XMLDOM.DOMNode;
		v_q						CLOB;

		v_pn					DBMS_XMLDOM.DOMNode;
		v_null					DBMS_XMLDOM.DOMNode;

		v_cnl					DBMS_XMLDOM.DOMNodeList;
		v_cn					DBMS_XMLDOM.DOMNode;

        v_count                 NUMBER;
	BEGIN
		v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(in_doc),'//question/option|//question/columnHeader');
		FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
			v_n := DBMS_XMLDOM.item(v_nl, idx);
			v_pn := DBMS_XMLDOM.getParentNode(v_n);

    		v_qopt_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');

			IF DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_pn), 'type') = 'matrix' THEN
				v_cnl := dbms_xslprocessor.selectNodes(v_pn,'radioRow');

				FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_cnl) - 1 LOOP
					v_cn := DBMS_XMLDOM.item(v_cnl, idx2);

					v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_cn), 'id');

					DBMS_LOB.CreateTemporary(v_q, TRUE);
					DBMS_XMLDOM.writeToClob(v_n, v_q);

					UPDATE csr.question_option
					   SET question_option_xml = v_q
					 WHERE question_option_id = v_qopt_id
					   AND question_id = v_question_id
					   AND question_version = in_version
					   AND app_sid = in_app_sid;

					v_count := SQL%ROWCOUNT;

                    IF v_count = 0 THEN
                        dbms_output.put_line('question_option_id = ' || v_qopt_id || ', version = ' || in_version);
                    END IF;

					DBMS_LOB.FreeTemporary(v_q);
				END LOOP;
            ELSE
                v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_pn), 'id');

				DBMS_LOB.CreateTemporary(v_q, TRUE);
                DBMS_XMLDOM.writeToClob(v_n, v_q);

                UPDATE csr.question_option
                   SET question_option_xml = v_q
                 WHERE question_option_id = v_qopt_id
                   AND question_id = v_question_id
                   AND question_version = in_version
				   AND app_sid = in_app_sid;

				v_count := SQL%ROWCOUNT;

                IF v_count = 0 THEN
                    dbms_output.put_line('question_option_id = ' || v_qopt_id || ', question_id = ' || v_question_id ||', version = ' || in_version);
                END IF;

				DBMS_LOB.FreeTemporary(v_q);
			END IF;
		END LOOP;
	END ExtractQuestionOptionXML;
BEGIN
	dbms_output.enable(null);

	FOR r IN (
		SELECT app_sid, question_xml, survey_version
		  FROM csr.quick_survey_version
		 ORDER BY survey_sid, survey_version ASC
	) LOOP
		v_doc := DBMS_XMLDOM.newdomdocument(r.question_xml);

		ExtractQuestionOptionXML(r.app_sid, v_doc, r.survey_version);
		ExtractQuestionXML(r.app_sid, v_doc, r.survey_version);

		DBMS_XMLDOM.freeDocument(v_doc);
	END LOOP;

	COMMIT;
END;
/

DECLARE
	v_xml		VARCHAR2(4000);
BEGIN
	FOR r IN (
		SELECT qv.question_id, q.question_type, q.lookup_key, qv.weight, qv.remember_answer, qv.count_question, qv.label, qv.question_version, qv.app_sid, qv.action, qv.question_draft, qv.score
		  FROM csr.question q
		  JOIN csr.question_version qv ON qv.question_id = q.question_id AND qv.app_sid = q.app_sid
		 WHERE question_xml IS NULL
	) LOOP
		IF r.question_type = 'section' THEN
			v_xml := '<section id="' || r.question_id || '" rememberAnswer="' || r.remember_answer || '" weight="' || r.weight || '" lookupKey="' || r.lookup_key || '" score="' || r.score || '"><description>' || r.label || '</description><tags/><helpText/><helpTextLong/><helpTextLongLink/><infoPopup/></section>';
		ELSIF r.question_type = 'pagebreak' THEN
			v_xml := '<pageBreak id="' || r.question_id || '" />';
		ELSIF r.question_type = 'checkbox' THEN
			v_xml := '<checkbox id="' || r.question_id || '" action="' || r.action || '" lookupKey="' || r.lookup_key || '" score="' || r.score || '"><description>'|| r.label || '</description></checkbox>';
		ELSE
			v_xml := '<question type="'|| r.question_type || '" id="' || r.question_id || '" weight="' || r.weight || '" rememberAnswer="' || r.remember_answer || '" countQuestion="' || r.count_question || '" lookupKey="' || r.lookup_key || '" score="' || r.score || '"><description>' || r.label || '</description><tags /><helpText></helpText><helpTextLong></helpTextLong><helpTextLongLink></helpTextLongLink><infoPopup></infoPopup></question>';
		END IF;

		UPDATE csr.question_version
		   SET question_xml = to_clob(v_xml)
		 WHERE question_id = r.question_id
		   AND question_version = r.question_version
		   AND app_sid = r.app_sid;
	END LOOP;

	COMMIT;
END;
/

DECLARE
	v_xml		VARCHAR2(4000);
BEGIN
	FOR r IN (
		SELECT qo.question_option_id, qo.label, qo.color, qo.app_sid, qo.question_id, qo.question_version, qo.question_draft, qo.lookup_key, qo.score, q.question_type
		  FROM csr.question_option qo
		  JOIN csr.question q ON qo.question_id = q.question_id AND qo.app_sid = q.app_sid
		 WHERE question_option_xml IS NULL
	) LOOP
		IF r.question_type = 'radiorow' THEN
			v_xml := '<columnHeader id="' || r.question_option_id ||'" lookupKey="' || r.lookup_key || '" score="' || r.score || '">' || r.label || '</columnHeader>';
		ELSIF r.question_type = 'matrix' THEN
			v_xml := '<radioRow id="' || r.question_option_id ||'" lookupKey="' || r.lookup_key || '" score="' || r.score || '"><description>' || r.label || '</description></radioRow>';
		ELSE
			v_xml := '<option id="' || r.question_option_id ||'" color="' || r.color || '" lookupKey="' || r.lookup_key || '" score="' || r.score || '">' || r.label || '</option>';
		END IF;

		UPDATE csr.question_option
		   SET question_option_xml = to_clob(v_xml)
		 WHERE question_id = r.question_id
		   AND question_version = r.question_version
		   AND app_sid = r.app_sid;
	END LOOP;

	COMMIT;
END;
/


ALTER TABLE CSR.QUESTION_VERSION MODIFY QUESTION_XML NOT NULL;
ALTER TABLE CSR.QUESTION_OPTION MODIFY QUESTION_OPTION_XML NOT NULL;


-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.question_library_pkg AS NULL END question_library_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.question_library_pkg AS END question_library_pkg;
/

GRANT EXECUTE ON csr.question_library_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\question_library_pkg
@..\quick_survey_pkg
@..\csrimp\imp_pkg

@..\question_library_body
@..\csrimp\imp_body
@..\schema_body
@..\quick_survey_body
@..\testdata_body

@update_tail
