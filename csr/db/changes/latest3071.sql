define version=3071
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/

ALTER TABLE CSR.QUESTION_VERSION ADD (
	QUESTION_XML			CLOB NULL
);
ALTER TABLE CSR.QUESTION_OPTION ADD (
	QUESTION_OPTION_XML		CLOB NULL
);

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
BEGIN
	dbms_output.enable(null);
	FOR r IN (
		SELECT app_sid, question_xml, survey_version
		  FROM csr.quick_survey_version
		 ORDER BY survey_sid, survey_version ASC
	) LOOP
		v_doc := DBMS_XMLDOM.newdomdocument(r.question_xml);
		ExtractQuestionXML(r.app_sid, v_doc, r.survey_version);
		DBMS_XMLDOM.freeDocument(v_doc);
	END LOOP;
	COMMIT;
END;
/

DECLARE
    v_doc					DBMS_XMLDOM.DOMDocument;
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
		   AND app_sid = r.app_sid
           AND question_option_id = r.question_option_id;
	END LOOP;
	COMMIT;
END;
/

ALTER TABLE CSR.QUESTION_VERSION MODIFY QUESTION_XML NOT NULL;
ALTER TABLE CSR.QUESTION_OPTION MODIFY QUESTION_OPTION_XML NOT NULL;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_QUESTION_XML
(
	ID			NUMBER(10)		NOT NULL,
	XML			CLOB			NOT NULL,
	CONSTRAINT PK_TEMP_QUESTION_XML PRIMARY KEY (ID)
)
ON COMMIT DELETE ROWS
;
CREATE TABLE csr.ftp_profile_log (
	app_sid					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ftp_profile_id			NUMBER(10) 		NOT NULL,
	changed_dtm				DATE 			NOT NULL,
	changed_by_user_sid		NUMBER(10) 		NOT NULL,
	message					VARCHAR2(1024) 	NOT NULL
);
CREATE INDEX CSR.IDX_FTP_PROFILE_LOG ON CSR.FTP_PROFILE_LOG(APP_SID)
;
DECLARE
	v_curr_val  NUMBER(10);
BEGIN
	SELECT csr.comp_item_region_log_id_seq.nextval INTO v_curr_val FROM dual;
	EXECUTE IMMEDIATE 'CREATE SEQUENCE csr.flow_item_audit_log_id_seq START WITH ' || v_curr_val;
END;
/
DROP SEQUENCE csr.comp_item_region_log_id_seq;
CREATE TABLE csr.doc_folder_name_translation (
	app_sid				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	doc_folder_sid		NUMBER(10, 0)		NOT NULL,
	lang				VARCHAR2(10)		NOT NULL,
	translated			VARCHAR2(1023)		NOT NULL,
	CONSTRAINT pk_doc_folder_name_translation PRIMARY KEY (app_sid, doc_folder_sid, lang)
);
CREATE TABLE csrimp.doc_folder_name_translation (
	csrimp_session_id	NUMBER(10, 0) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	doc_folder_sid		NUMBER(10, 0)		NOT NULL,
	lang				VARCHAR2(10)		NOT NULL,
	translated			VARCHAR2(1023)		NOT NULL,
	CONSTRAINT pk_doc_folder_name_translation PRIMARY KEY (csrimp_session_id, doc_folder_sid, lang)
);


ALTER TABLE csr.question ADD (
	latest_question_version NUMBER(10),
	latest_question_draft NUMBER(1)
);
ALTER TABLE csr.question ADD (
	CONSTRAINT fk_latest_question_version FOREIGN KEY (app_sid, question_id, latest_question_version, latest_question_draft)
	REFERENCES csr.question_version(app_sid, question_id, question_version, question_draft)
	DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX csr.ix_latest_question_version ON csr.question(app_sid, question_id, latest_question_version, latest_question_draft);
ALTER TABLE csrimp.question ADD (
	latest_question_version NUMBER(10) NOT NULL,
	latest_question_draft NUMBER(1) NOT NULL
);
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Get the latest question version by question ID
	UPDATE csr.question q
	   SET latest_question_version = (
			SELECT MAX(question_version)
			  FROM csr.question_version qv
			 WHERE q.app_sid = qv.app_sid
			   AND q.question_id = qv.question_id
		);
	
	-- Of that version, get the whether there's a draft version
	UPDATE csr.question q
	   SET latest_question_draft = (
			SELECT MAX(question_draft)
			  FROM csr.question_version qv
			 WHERE q.app_sid = qv.app_sid
			   AND q.question_id = qv.question_id
			   AND q.latest_question_version = qv.question_version
		);
	
END;
/
ALTER TABLE csr.question MODIFY latest_question_version NOT NULL;
ALTER TABLE csr.question MODIFY latest_question_draft NOT NULL;
ALTER TABLE csrimp.gresb_indicator_mapping MODIFY ind_sid NULL;
ALTER TABLE csrimp.compliance_item MODIFY title VARCHAR2(1024);
ALTER TABLE csrimp.compliance_item MODIFY summary VARCHAR2(4000);
ALTER TABLE csrimp.compliance_permit MODIFY permit_sub_type_id NULL;
ALTER TABLE csrimp.compliance_permit_condition MODIFY condition_sub_type_id NULL;
CREATE TABLE csrimp.compliance_permit_history (
	CSRIMP_SESSION_ID				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	prev_permit_id					NUMBER(10,0) NOT NULL,
	next_permit_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_permit_history PRIMARY KEY (CSRIMP_SESSION_ID, prev_permit_id, next_permit_id),
	CONSTRAINT fk_compliance_permit_hist_is FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
ALTER TABLE chain.company_product_tr
	ADD last_changed_dtm_description DATE;
ALTER TABLE chain.company_request_action ADD SENT_DTM DATE;
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
CREATE UNIQUE INDEX uk_ftp_profile_label ON csr.ftp_profile(app_sid, lower(label));
DROP TABLE csr.ftp_default_profile;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_SETTINGS
ADD OVERLAP_ACTION VARCHAR(10) DEFAULT 'ERROR' NOT NULL;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_SETTINGS
ADD CONSTRAINT CK_AUTO_IMP_COR_DATA_SET_OLAP CHECK (OVERLAP_ACTION IN ('ERROR', 'SUM'));
ALTER TABLE CHAIN.BSCI_SUPPLIER
ADD (
	CODE_OF_CONDUCT_SIGN_INT	VARCHAR2(255) NULL,
	SA8000_CERTIFIED			VARCHAR2(255) NULL,
	AUDIT_CERTIFICATION			VARCHAR2(4000) NULL
);
ALTER TABLE CHAIN.BSCI_AUDIT
ADD (
	EXECSUMM_AUDIT_RPT			VARCHAR2(4000) NULL
);
ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER
ADD (
	CODE_OF_CONDUCT_SIGN_INT	VARCHAR2(255) NULL,
	SA8000_CERTIFIED			VARCHAR2(255) NULL,
	AUDIT_CERTIFICATION			VARCHAR2(4000) NULL
);
ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
ADD (
	EXECSUMM_AUDIT_RPT			VARCHAR2(4000) NULL
);
ALTER TABLE csr.compliance_options ADD auto_involve_managers NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.compliance_options ADD auto_involve_managers NUMBER(1,0) NOT NULL;
ALTER TABLE csr.compliance_item_region_log
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csr.compliance_item_region_log
	RENAME TO flow_item_audit_log;
	
ALTER TABLE csr.flow_item_audit_log ADD (
	PARAM_1			VARCHAR2(255),
	PARAM_2			VARCHAR2(255),
	PARAM_3			VARCHAR2(255)
);
ALTER INDEX csr.pk_compliance_item_region_log RENAME TO pk_flow_item_audit_log;
ALTER INDEX csr.ix_compliance_it_user_sid RENAME TO ix_flow_it_aud_log_user_sid;
ALTER INDEX csr.ix_compliance_it_flow_item_id RENAME TO ix_flow_it_aud_log_flow_it_id;
ALTER TABLE csrimp.compliance_item_region_log
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csrimp.compliance_item_region_log
	RENAME TO flow_item_audit_log;
	
ALTER TABLE csrimp.flow_item_audit_log ADD (
	PARAM_1			VARCHAR2(255),
	PARAM_2			VARCHAR2(255),
	PARAM_3			VARCHAR2(255)
);
ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME COLUMN old_comp_item_region_log_id TO old_flow_item_audit_log_id;
	
ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME COLUMN new_comp_item_region_log_id TO new_flow_item_audit_log_id;
ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME TO map_flow_item_audit_log;
ALTER TABLE csr.temp_compliance_log_ids
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csr.temp_compliance_log_ids
	RENAME TO temp_flow_item_audit_log;
ALTER TABLE csr.flow_item_audit_log DROP CONSTRAINT FK_CMP_ITM_REG_LOG_CMP_ITM_REG;
ALTER TABLE CSR.METER_READING_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSR.METER_SOURCE_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSR.METER_ORPHAN_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSR.METER_INSERT_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSRIMP.METER_READING_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSRIMP.METER_SOURCE_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE CSRIMP.METER_ORPHAN_DATA ADD (
	NOTE		VARCHAR2(4000)
);
ALTER TABLE csrimp.map_compl_activity_sub_type ADD (
	old_complianc_activity_type_id	NUMBER(10) NOT NULL, 
	new_complianc_activity_type_id	NUMBER(10) NOT NULL
);
ALTER TABLE csrimp.map_compl_activity_sub_type
DROP CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE;
ALTER TABLE csrimp.map_compl_activity_sub_type
DROP CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE;
ALTER TABLE csrimp.map_compl_activity_sub_type ADD
CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_ACTIVITY_TYPE_ID, OLD_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX;
ALTER TABLE csrimp.map_compl_activity_sub_type ADD
CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_ACTIVITY_TYPE_ID, NEW_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX;
ALTER TABLE csrimp.map_compl_permi_sub_type ADD (
	old_compliance_permit_type_id	NUMBER(10) NOT NULL, 
	new_compliance_permit_type_id	NUMBER(10) NOT NULL
);
ALTER TABLE csrimp.map_compl_permi_sub_type
DROP CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE;
ALTER TABLE csrimp.map_compl_permi_sub_type
DROP CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE;
ALTER TABLE csrimp.map_compl_permi_sub_type ADD
CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_TYPE_ID, OLD_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX;
ALTER TABLE csrimp.map_compl_permi_sub_type ADD
CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_TYPE_ID, NEW_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX;
	
ALTER TABLE csrimp.map_complia_condition_sub_type ADD (
	old_complian_condition_type_id	NUMBER(10) NOT NULL, 
	new_complian_condition_type_id	NUMBER(10) NOT NULL
);
ALTER TABLE csrimp.map_complia_condition_sub_type
DROP CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE;
ALTER TABLE csrimp.map_complia_condition_sub_type
DROP CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE;
ALTER TABLE csrimp.map_complia_condition_sub_type ADD
CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID, OLD_COMP_CONDITION_SUB_TYPE_ID) USING INDEX;
ALTER TABLE csrimp.map_complia_condition_sub_type ADD
CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID, NEW_COMP_CONDITION_SUB_TYPE_ID) USING INDEX;
ALTER TABLE csr.doc_folder_name_translation ADD CONSTRAINT fk_df_name_translation_df
	FOREIGN KEY (app_sid, doc_folder_sid)
	REFERENCES csr.doc_folder(app_sid, doc_folder_sid);
ALTER TABLE csrimp.doc_folder_name_translation ADD CONSTRAINT fk_doc_folder_name_tr_is
	FOREIGN KEY (csrimp_session_id)
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
ALTER TABLE CSR.CUSTOMER ADD SHOW_ADDITIONAL_AUDIT_INFO NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CHK_SHOW_ADDITIONAL_AUDIT_INFO CHECK (SHOW_ADDITIONAL_AUDIT_INFO IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD SHOW_ADDITIONAL_AUDIT_INFO NUMBER(1) NOT NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD SHOW_AUDIT_COORDINATOR NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD CONSTRAINT CHK_SHOW_AUDIT_COORDINATOR CHECK (SHOW_AUDIT_COORDINATOR IN (0,1));
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS ADD SHOW_AUDIT_COORDINATOR NUMBER(1) NOT NULL;


grant select, insert, update, delete on csrimp.compliance_permit_history to tool_user;
grant select, insert, update on csr.compliance_permit_history to csrimp;
GRANT SELECT ON csr.flow_item_audit_log_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_item_audit_log TO tool_user;
GRANT INSERT, UPDATE ON csr.doc_folder_name_translation TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.doc_folder_name_translation TO tool_user;
GRANT EXECUTE ON csr.T_USER_FILTER_ROW TO chain;
GRANT EXECUTE ON csr.T_USER_FILTER_TABLE TO chain;




CREATE OR REPLACE VIEW csr.v$question AS
	SELECT qv.app_sid, qv.question_id, qv.question_version, qv.question_draft, qv.parent_id, qv.parent_version, qv.parent_draft, qv.label, qv.pos, qv.score, qv.max_score, qv.upload_score,
		qv.weight, qv.dont_normalise_score, qv.has_score_expression, qv.has_max_score_expr, qv.remember_answer, qv.count_question, qv.action,
		q.owned_by_survey_sid, q.question_type, q.custom_question_type_id, q.lookup_key, q.maps_to_ind_sid, q.measure_sid
	  FROM csr.question_version qv
	  JOIN csr.question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM csr.meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		)
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost,
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference,
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid,
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id,
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, 
		REPLACE(STRAGG(x.note), ',', '; ') note,
		NULL reference, NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid,
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask, x.auto_source
	FROM (
		-- Consumption (value part)
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.consumption val_number, NULL cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (value part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.consumption cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Consumption (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;
CREATE OR REPLACE VIEW csr.v$doc_folder AS
	SELECT df.doc_folder_sid, df.description, df.lifespan_is_override, df.lifespan,
		   df.approver_is_override, df.approver_sid, df.company_sid, df.is_system_managed,
		   df.property_sid, dfnt.lang, dfnt.translated
	  FROM doc_folder df
	  JOIN doc_folder_name_translation dfnt ON df.app_sid = dfnt.app_sid AND df.doc_folder_sid = dfnt.doc_folder_sid
	 WHERE dfnt.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');




UPDATE csr.std_measure_conversion
   SET A = 0.00000000027777777778
 WHERE std_measure_conversion_id = 29;
UPDATE csr.std_measure_conversion
   SET A = 0.00000000000027777777778
 WHERE std_measure_conversion_id = 15797;
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE csr.batch_job
	   SET result ='Cancelled by cr360, ref: DE4660',
	   	   completed_dtm = SYSDATE
	 WHERE batch_job_type_id = 47
	   AND attempts > 1
	   AND completed_dtm IS NULL;
END;
/
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (31, 'condition', 'Updated');
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (64, 'Product description translation export', null, 'batch-exporter', 0, null, 120);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (65, 'Product description translation import', null, 'batch-importer', 0, null, 120);
INSERT INTO csr.batched_export_type (batch_job_type_id, label, assembly)
	VALUES (64, 'Product description translation export', 'Credit360.ExportImport.Export.Batched.Exporters.ProductDescriptionTranslationExporter');
INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (65, 'Product description translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.ProductDescriptionTranslationImporter');
DECLARE
v_util_script_id NUMBER(10);
BEGIN
  SELECT MAX(util_script_id) 
		INTO v_util_script_id
    FROM csr.util_script;
	
  v_util_script_id := v_util_script_id + 1;
  
  INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
			  VALUES (v_util_script_id,'Add US EGrid values','Add US EGrid values to a region and all its children','AddUSEGridValues',null);
	
  INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
			  VALUES (v_util_script_id, 'Region sid', 'The sid of the region to link e-grid references', 1);
	
END;
/
INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
VALUES (5031, 'Company relationship request approved',
		'A new relationship created to a supplier.',
		'The company who accepted the relationship.',
		8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'REQUESTED_COMPANY', 'Relationship requested to', 'The company the relationship was requested to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'REQUESTING_COMPANY', 'Relationship requested by', 'The company the relationship is requested by', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'COMPANY_URL', 'Link to company', 'Link to the company that was created or matched', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5031, 0, 'FROM_EMAIL', 'From email', 'Address the alert was sent from', 8);
INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
VALUES (5032, 'Company onboarding request refused',
		'A new company request refused.',
		'The company who denied the new supplier request.',
		8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'REQUESTED_COMPANY', 'Relationship requested to', 'The company the relationship was requested to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'REQUESTING_COMPANY', 'Relationship requested by', 'The company the relationship is requested by', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5032, 0, 'FROM_EMAIL', 'From email', 'Address the alert was sent from', 7);

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 10 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  														/* CT_COMPANIES*/
		in_capability		=> 'Manage product certification requirements', 				/* MANAGE_PRODUCT_CERT_REQS */
		in_perm_type		=> 1 															/* BOOLEAN_PERMISSION */
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  														/* CT_COMPANIES*/
		in_capability		=> 'Product certifications', 									/* PRODUCT_CERTIFICATIONS */
		in_perm_type		=> 0 															/* SPECIFIC_PERMISSION */
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  															/* CT_SUPPLIERS*/
		in_capability		=> 'Product supplier certifications', 							/* PRODUCT_SUPPLIER_CERTS */
		in_perm_type		=> 0, 															/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  															/* CT_ON_BEHALF_OF*/
		in_capability		=> 'Product supplier certifications of suppliers', 				/* PRODUCT_SUPP_OF_SUPP_CERTS */
		in_perm_type		=> 0, 															/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE csr.pct_ownership
	   SET start_dtm = add_months(end_dtm, -12)
	 WHERE start_dtm = TO_DATE('01/01/0016', 'DD/MM/RRRR');
END;
/
ALTER TABLE csr.pct_ownership DROP CONSTRAINT ck_pct_ownership_dates;
ALTER TABLE csr.pct_ownership ADD CONSTRAINT ck_pct_ownership_dates CHECK
(start_dtm = TRUNC(start_dtm, 'MON') AND start_dtm >= TO_DATE('01/01/1900', 'DD/MM/YYYY') AND (end_dtm IS NULL OR (end_dtm = TRUNC(end_dtm, 'MON') AND end_dtm >= TO_DATE('01/01/1900', 'DD/MM/YYYY') AND end_dtm > start_dtm)));
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.tab_portlet t
	   SET t.state = REPLACE(t.state, 'Property Compliance RAG Status', 'Site Compliance RAG Status')
	 WHERE t.tab_portlet_id IN (
		SELECT tp.tab_portlet_id 
		  FROM csr.tab_portlet tp
		  JOIN csr.customer_portlet cp ON tp.app_sid = cp.app_sid AND tp.customer_portlet_sid = cp.customer_portlet_sid
		 WHERE cp.portlet_id = 1048
		   AND dbms_lob.instr(tp.state, 'Property Compliance RAG Status') > 0
	);
	
	UPDATE csr.tab_portlet
	   SET state = REPLACE(state, 'Surveys waiting reply', 'Surveys awaiting reply')
	 WHERE tab_portlet_id IN (
		SELECT tp.tab_portlet_id 
		  FROM csr.tab_portlet tp
		  JOIN csr.customer_portlet cp ON tp.app_sid = cp.app_sid AND tp.customer_portlet_sid = cp.customer_portlet_sid
		 WHERE cp.portlet_id = 1025
		   AND dbms_lob.instr(tp.state, 'Surveys waiting reply') > 0
	);
END;
/
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'DUE_DTM', 'Due date', 'The date the issue should be resolved by', 18);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_TYPE_DESCRIPTION', 'Issue type', 'The description of the issue type', 20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'DUE_DTM', 'Due date', 'The date the issue should be resolved by', 21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 23);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_ID', 'Issue ID', 'The issue ID', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_LABEL', 'Issue label', 'The label of the issue', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_ID', 'Issue ID', 'The issue ID', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_LABEL', 'Issue label', 'The label of the issue', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 14);
UPDATE CSR.default_alert_template_body 
   SET item_html = 
	'<template><p><mergefield name="CRITICAL"/> <mergefield name="ISSUE_LABEL"/> ' || 
		'assigned to <mergefield name="ASSIGNED_TO"/> at <mergefield name="ISSUE_REGION"/> ' ||
		'expires on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/>' ||
	'</p></template>'
 WHERE std_alert_type_id IN (60, 61) AND lang = 'en';
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit audit log tab', '/csr/site/compliance/controls/FlowItemAuditLogTab.js', 'Credit360.Compliance.Controls.FlowItemAuditLogTab', 'Credit360.Compliance.Plugins.FlowItemAuditLogTab', 'Shows the audit history of a permit item.');
BEGIN
	UPDATE csr.auto_imp_importer_settings
	   SET mapping_xml = INSERTCHILDXML(
	   		mapping_xml, 
			'/columnMappings/column[@name="Url"]', 
			'@column-type', 
			'note')
	 WHERE EXISTSNODE(mapping_xml, '/columnMappings/column[@name="Url"]') = 1			-- Where the column name is "Url"
	   AND EXISTSNODE(mapping_xml, '/columnMappings/column[@column-type="note"]') = 0	-- and no nodes are already set to the "Note" column type
	   AND automated_import_class_sid IN (
		SELECT automated_import_class_sid
		  FROM csr.meter_raw_data_source
	);
END;
/
BEGIN
	security.user_pkg.LogonAdmin(NULL);
	UPDATE csr.issue_type 
	   SET allow_critical = 1
	 WHERE issue_type_id = 22;
END;
/
UPDATE security.menu
   SET description = 'Permits'
 WHERE action = '/csr/site/compliance/permitlist.acds'
   AND description = 'Permit Library';
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 21, 'Permit actions tab', '/csr/site/compliance/controls/PermitActionsTab.js', 'Credit360.Compliance.Controls.PermitActionsTab', 'Credit360.Compliance.Plugins.PermitActionsTab', 'Shows permit actions.');
INSERT INTO cms.col_type
(col_type, description) 
VALUES
(40, 'Permit');
	
UPDATE chain.card 
   SET description = 'CMS Data Adapter',
		class_type = 'NPSL.Cms.Cards.CmsAdapter',
		js_include = '/fp/cms/filters/CmsAdapter.js',
		js_class_type = 'NPSL.Cms.Filters.CmsFilterAdapter'
 WHERE LOWER(js_class_type) = LOWER('NPSL.Cms.Filters.CmsFilterAdaptor');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_product_filter_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_product_filter_card_id         chain.card.card_id%TYPE;
BEGIN
	v_desc := 'Permit CMS Adapter';
	v_class := 'Credit360.Compliance.Cards.PermitCmsFilterAdapter';
	v_js_path := '/csr/site/compliance/filters/PermitCmsFilterAdapter.js';
	v_js_class := 'Credit360.Compliance.Filters.PermitCmsFilterAdapter';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
		 RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	v_actions := chain.T_STRING_LIST('default');
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Permit CMS Filter',
				'csr.permit_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Permit CMS Filter',
					   helper_pkg = 'csr.permit_report_pkg'
				 WHERE card_id = v_card_id;
	END;
END;
/
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_product_filter_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_product_filter_card_id         chain.card.card_id%TYPE;
BEGIN
	v_desc := 'User CMS Adapter';
	v_class := 'Credit360.Schema.Cards.UserCmsFilterAdapter';
	v_js_path := '/csr/site/users/list/filters/UserCmsFilterAdapter.js';
	v_js_class := 'Credit360.Users.Filters.UserCmsFilterAdapter';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
		 RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	v_actions := chain.T_STRING_LIST('default');
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'User CMS Filter',
				'csr.user_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'User CMS Filter',
					   helper_pkg = 'csr.user_report_pkg'
				 WHERE card_id = v_card_id;
	END;
END;
/
 
DECLARE
	PROCEDURE SetGroupCards(
		in_group_name			IN  chain.card_group.name%TYPE,
		in_card_js_types		IN  chain.T_STRING_LIST
	)
	AS
		v_group_id				chain.card_group.card_group_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
		v_pos					NUMBER(10) DEFAULT 0;
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
		
		DELETE FROM chain.card_group_progression
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		DELETE FROM chain.card_group_card
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		-- empty array check
		IF in_card_js_types IS NULL OR in_card_js_types.COUNT = 0 THEN
			RETURN;
		END IF;
		
		FOR i IN in_card_js_types.FIRST .. in_card_js_types.LAST 
		LOOP		
			SELECT card_id
			  INTO v_card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER(in_card_js_types(i));
			INSERT INTO chain.card_group_card
			(card_group_id, card_id, position)
			VALUES
			(v_group_id, v_card_id, v_pos);
			
			v_pos := v_pos + 1;
		
		END LOOP;		
	END;		
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
		  JOIN chain.card_group_card cgc on c.app_sid = cgc.app_sid
		 WHERE card_group_id = 47 
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('User Data Filter', chain.T_STRING_LIST('Credit360.Users.Filters.UserDataFilter', 'Credit360.Users.Filters.UserCmsFilterAdapter'));
	END LOOP;
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
		  JOIN csr.compliance_options co on co.app_sid = c.app_sid
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('Compliance Permit Filter', chain.T_STRING_LIST('Credit360.Compliance.Filters.PermitFilter', 'Credit360.Compliance.Filters.PermitCmsFilterAdapter'));
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);
		INSERT INTO csr.doc_folder_name_translation (doc_folder_sid, lang, translated)
		SELECT df.doc_folder_sid, cl.lang, NVL(so.name, so.sid_id) AS translated
		  FROM csr.doc_folder df
		  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
		 CROSS JOIN csr.v$customer_lang cl
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM csr.doc_folder_name_translation
			 WHERE doc_folder_sid = df.doc_folder_sid 
			   AND lang = cl.lang
		 );
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/




CREATE OR REPLACE PACKAGE csr.question_library_pkg AS NULL END question_library_pkg;
/
CREATE OR REPLACE PACKAGE BODY csr.question_library_pkg AS END question_library_pkg;
/
GRANT EXECUTE ON csr.question_library_pkg TO web_user;


@..\chain\filter_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\csr_data_pkg
@..\compliance_pkg
@..\chain\company_product_pkg
@..\util_script_pkg
@..\chain\company_pkg
@..\question_library_pkg
@..\quick_survey_pkg
@..\csrimp\imp_pkg
@..\chain\chain_pkg
@..\audit_pkg
@..\automated_export_import_pkg
@..\automated_import_pkg
@..\chain\product_report_pkg
@..\chain\certification_pkg
@..\chain\bsci_pkg
@..\factor_pkg
@..\issue_pkg
@..\permit_pkg
@..\schema_pkg
@..\meter_monitor_pkg
@..\compliance_library_report_pkg
@..\permit_report_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\doc_folder_pkg
@..\chain\company_user_pkg


@..\schema_body
@..\question_library_report_body
@..\quick_survey_body
@..\audit_report_body
@..\issue_report_body
@..\non_compliance_report_body
@..\property_report_body
@..\quick_survey_report_body
@..\chain\activity_report_body
@..\chain\business_rel_report_body
@..\chain\company_filter_body
@..\chain\product_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\csrimp\imp_body
@..\compliance_body
@..\compliance_setup_body
@..\flow_body
@..\chain\company_product_body
@..\util_script_body
@..\chain\company_body
@..\chain\setup_body
@..\question_library_body
@..\testdata_body
@..\chain\product_supplier_report_body
@..\chain\certification_report_body
@..\audit_body
@..\region_body
@..\automated_export_import_body
@..\automated_import_body
@..\meter_monitor_body
@..\enable_body
@..\chain\certification_body
@..\meter_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\chain\bsci_body
@..\factor_body
@..\delegation_body
@..\issue_body
@..\permit_body
@..\csr_app_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\permit_report_body
@..\user_report_body
@..\..\..\aspen2\cms\db\tab_body
@..\doc_lib_body
@..\doc_folder_body
@..\supplier_body
@ ..\quick_survey_body
@..\chain\company_user_body
@..\customer_body
@..\chain\helper_body
@..\chain\supplier_audit_body



@update_tail
