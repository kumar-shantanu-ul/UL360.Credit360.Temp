define version=3143
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
CREATE TABLE SURVEYS.ANSWER_CUSTOM_OPTION (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	CUSTOM_OPTION_ID			NUMBER(10, 0)	NOT NULL,
	ANSWER_ID 					NUMBER(10, 0) 	NOT NULL,
	QUESTION_ID 				NUMBER(10, 0) 	NOT NULL,
	QUESTION_VERSION 			NUMBER(10, 0) 	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		NOT NULL,
	LABEL						VARCHAR2(255)	NOT NULL,
	SELECTED					NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_ANSWER_CUSTOM_OPTION PRIMARY KEY (APP_SID, CUSTOM_OPTION_ID, ANSWER_ID),
	CONSTRAINT CHK_ACO_SELECTED_0_1 CHECK (SELECTED IN (0,1)),
	CONSTRAINT FK_AQO_ANSWER FOREIGN KEY (APP_SID, ANSWER_ID) REFERENCES SURVEYS.ANSWER(APP_SID, ANSWER_ID),
	CONSTRAINT FK_AQO_QUESTION_VERSION FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT) REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
);

ALTER TABLE surveys.answer ADD hidden NUMBER(1) DEFAULT 0;

UPDATE surveys.answer 
   SET hidden = 0
 WHERE hidden IS NULL;

 ALTER TABLE surveys.answer 
	 MODIFY hidden NUMBER(1) DEFAULT 0 NOT NULL ;

DROP TABLE SURVEYS.ANSWER_FILE;
DROP TABLE SURVEYS.RESPONSE_FILE;
CREATE TABLE SURVEYS.SUBMISSION_FILE(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SUBMISSION_ID			NUMBER(10, 0)	NOT NULL,
	FILENAME				VARCHAR2(255)	NOT NULL,
	URI 					VARCHAR2(2000)	NOT NULL,
	UPLOADED_DTM			DATE			DEFAULT SYSDATE NOT NULL,
	UPLOADED_BY_USER_SID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SUBMISSION_FILE PRIMARY KEY (APP_SID, SUBMISSION_ID, FILENAME, URI)
)
;
CREATE INDEX SURVEYS.IX_SUB_FILE_BY_URI ON SURVEYS.SUBMISSION_FILE(APP_SID, FILENAME, URI)
;
CREATE TABLE SURVEYS.ANSWER_FILE(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_FILE_ID		NUMBER(10, 0)	NOT NULL,
	ANSWER_ID			NUMBER(10, 0)	NOT NULL,
	SUBMISSION_ID		NUMBER(10, 0)	NOT NULL,
	FILENAME			VARCHAR2(255)	NOT NULL,
	URI					VARCHAR2(400)	NOT NULL,
	CAPTION				VARCHAR2(1023),
	CONSTRAINT PK_SURVEY_ANSWER_FILE PRIMARY KEY (APP_SID, ANSWER_FILE_ID),
	CONSTRAINT UK_SURVEY_ANSWER_FILE UNIQUE (APP_SID, ANSWER_FILE_ID, ANSWER_ID, SUBMISSION_ID),
	CONSTRAINT UK_SURVEYS_ANSWER_FILE_A UNIQUE (APP_SID, ANSWER_ID, SUBMISSION_ID, FILENAME, URI)
)
;
CREATE INDEX SURVEYS.IX_ANS_FILE_SUB_ID ON SURVEYS.ANSWER_FILE(APP_SID, SUBMISSION_ID);
CREATE SEQUENCE CSR.ISSUE_TEMPLATE_ID_SEQ;
CREATE TABLE CSR.ISSUE_TEMPLATE (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ISSUE_TEMPLATE_ID				NUMBER(10)		NOT NULL,
	ISSUE_TYPE_ID					NUMBER(10)		NOT NULL,
	LABEL							VARCHAR2(2048)	NOT NULL,
	DESCRIPTION						CLOB			NULL,
	ASSIGN_TO_USER_SID				NUMBER(10)		NULL,
	DUE_DTM							DATE			NULL,
	DUE_DTM_RELATIVE				NUMBER(10)		NULL,
	DUE_DTM_RELATIVE_UNIT			VARCHAR2(1)		NULL,
	IS_URGENT						NUMBER(1)		NULL,
	IS_CRITICAL						NUMBER(1)		NULL,
	CONSTRAINT PK_ISSUE_TEMPLATE PRIMARY KEY (APP_SID, ISSUE_TEMPLATE_ID),
	CONSTRAINT CHK_IT_IS_URGENT CHECK (IS_URGENT IN (0, 1)),
	CONSTRAINT CHK_IT_IS_CRITICAL CHECK (IS_CRITICAL IN (0, 1)),
	CONSTRAINT CHK_IT_DUE_DTM CHECK((DUE_DTM_RELATIVE IS NULL AND DUE_DTM_RELATIVE_UNIT IS NULL) OR (DUE_DTM_RELATIVE IS NOT NULL AND DUE_DTM_RELATIVE_UNIT IS NOT NULL)),
	CONSTRAINT CHK_IT_DUE_DTM_REL_UNIT CHECK(DUE_DTM_RELATIVE_UNIT IN ('d','m'))
);
create index csr.ix_issue_templat_assign_to_use on csr.issue_template (app_sid, assign_to_user_sid);
create index csr.ix_issue_templat_issue_type_id on csr.issue_template (app_sid, issue_type_id);
CREATE TABLE CSR.ISSUE_TEMPLATE_CUSTOM_FIELD (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ISSUE_TEMPLATE_ID				NUMBER(10, 0)	NOT NULL,
	ISSUE_CUSTOM_FIELD_ID			NUMBER(10, 0)	NOT NULL,
	STRING_VALUE					VARCHAR2(255)	NULL,
	DATE_VALUE						DATE			NULL,
	CONSTRAINT PK_ISSUE_TEMP_CUST_FIELD PRIMARY KEY (APP_SID, ISSUE_TEMPLATE_ID, ISSUE_CUSTOM_FIELD_ID)
);
create index csr.ix_itcf_cust_fld_id on csr.issue_template_custom_field (app_sid, issue_custom_field_id);
CREATE TABLE CSR.ISSUE_TEMPLATE_CUST_FIELD_OPT (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ISSUE_TEMPLATE_ID				NUMBER(10, 0)	NOT NULL,
	ISSUE_CUSTOM_FIELD_ID			NUMBER(10, 0)	NOT NULL,
	ISSUE_CUSTOM_FIELD_OPT_ID		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_ISSUE_TEMP_CUST_FIELD_OPT PRIMARY KEY (APP_SID, ISSUE_TEMPLATE_ID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
);
create index csr.ix_itcfo_opt_id on csr.issue_template_cust_field_opt (app_sid, issue_custom_field_id, issue_custom_field_opt_id);
CREATE TABLE CSRIMP.ISSUE_TEMPLATE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_TEMPLATE_ID NUMBER(10,0) NOT NULL,
	ASSIGN_TO_USER_SID NUMBER(10,0),
	DESCRIPTION CLOB,
	DUE_DTM DATE,
	DUE_DTM_RELATIVE NUMBER(10,0),
	DUE_DTM_RELATIVE_UNIT VARCHAR2(1),
	ISSUE_TYPE_ID NUMBER(10,0) NOT NULL,
	IS_CRITICAL NUMBER(1,0),
	IS_URGENT NUMBER(1,0),
	LABEL VARCHAR2(2048) NOT NULL,
	CONSTRAINT PK_ISSUE_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_TEMPLATE_ID),
	CONSTRAINT FK_ISSUE_TEMPLATE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.ISSUE_TEMPLATE_CUSTOM_FIELD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_TEMPLATE_ID NUMBER(10,0) NOT NULL,
	ISSUE_CUSTOM_FIELD_ID NUMBER(10,0) NOT NULL,
	DATE_VALUE DATE,
	STRING_VALUE VARCHAR2(255),
	CONSTRAINT PK_ISSUE_TEMPLATE_CUSTOM_FIELD PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_TEMPLATE_ID, ISSUE_CUSTOM_FIELD_ID),
	CONSTRAINT FK_ISSUE_TEMPL_CUSTOM_FIELD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.ISSUE_TEMPLATE_CUST_FIELD_OPT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_TEMPLATE_ID NUMBER(10,0) NOT NULL,
	ISSUE_CUSTOM_FIELD_ID NUMBER(10,0) NOT NULL,
	ISSUE_CUSTOM_FIELD_OPT_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_ISSUE_TEMPLATE_CUST_FLD_OPT PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_TEMPLATE_ID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID),
	CONSTRAINT FK_ISSU_TEMP_CUST_FIELD_OPT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_ISSUE_TEMPLATE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_TEMPLATE_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_TEMPLATE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_TEMPLATE_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_TEMPLATE UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_TEMPLATE_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_TEMPLATE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE csr.non_compliance_type
  ADD is_default_survey_finding NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.non_compliance_type
  ADD CONSTRAINT chk_is_default_survey_finding CHECK (is_default_survey_finding IN (1, 0));
ALTER TABLE csrimp.non_compliance_type
  ADD is_default_survey_finding NUMBER(1,0) NOT NULL;
ALTER TABLE csrimp.non_compliance_type
  ADD CONSTRAINT chk_is_default_survey_finding CHECK (is_default_survey_finding IN (1, 0));
ALTER TABLE CSR.METERING_OPTIONS ADD
	PREVENT_MANUAL_FUTURE_READINGS	NUMBER(1)	DEFAULT 0 NOT NULL;
ALTER TABLE CSR.METERING_OPTIONS ADD
	CONSTRAINT CK_MET_OPT_PMFR_0_1 CHECK (PREVENT_MANUAL_FUTURE_READINGS IN(0,1));
ALTER TABLE CSRIMP.METERING_OPTIONS ADD
	PREVENT_MANUAL_FUTURE_READINGS	NUMBER(1)	DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.METERING_OPTIONS ADD
	CONSTRAINT CK_MET_OPT_PMFR_0_1 CHECK (PREVENT_MANUAL_FUTURE_READINGS IN(0,1));
ALTER TABLE csr.customer ADD calc_future_window NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csr.customer ADD CONSTRAINT chk_calc_future_window CHECK (calc_future_window >= 1 AND calc_future_window < 15);
ALTER TABLE csrimp.customer ADD calc_future_window NUMBER(2) NOT NULL;
ALTER TABLE csrimp.customer ADD CONSTRAINT chk_calc_future_window CHECK (calc_future_window >= 1 AND calc_future_window < 15);
ALTER TABLE surveys.question_version RENAME COLUMN remember_answer TO allow_copy_answer;
ALTER TABLE csr.customer MODIFY calc_start_dtm DEFAULT NULL;
ALTER TABLE csr.customer MODIFY calc_end_dtm DEFAULT NULL;
ALTER TABLE surveys.audit_log_detail MODIFY (
	new_value VARCHAR2(4000),
	old_value VARCHAR2(4000),
	user_disp_new_value VARCHAR2(4000),
	user_disp_old_value VARCHAR2(4000)
);
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_FILE
	FOREIGN KEY (APP_SID, SUBMISSION_ID, FILENAME, URI)
	REFERENCES SURVEYS.SUBMISSION_FILE(APP_SID, SUBMISSION_ID, FILENAME, URI)
;
ALTER TABLE SURVEYS.SUBMISSION_FILE ADD CONSTRAINT FK_SUBMISSION_FILE_RESPONSE
	FOREIGN KEY (APP_SID, SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION(APP_SID, SUBMISSION_ID)
;
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANS_FILE_SUB_ID
	FOREIGN KEY (APP_SID, SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION(APP_SID, SUBMISSION_ID)
;
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_ANSWER
	FOREIGN KEY (APP_SID, ANSWER_ID)
	REFERENCES SURVEYS.ANSWER (APP_SID, ANSWER_ID)
;
ALTER TABLE surveys.answer_custom_option DROP CONSTRAINT fk_aqo_question_version;
ALTER TABLE surveys.answer_custom_option DROP COLUMN question_id;
ALTER TABLE surveys.answer_custom_option DROP COLUMN question_draft;
ALTER TABLE surveys.answer_custom_option DROP COLUMN question_version;
ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION DROP CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK;
ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION ADD (
	ISSUE_TEMPLATE_ID				NUMBER(10, 0) NULL
);
create index csr.ix_quick_survey_ex_iss_temp on csr.quick_survey_expr_action (app_sid, issue_template_id);
ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION ADD (
	ISSUE_TEMPLATE_ID				NUMBER(10, 0) NULL
);
ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK 
CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
	  AND ISSUE_TEMPLATE_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
	  AND ISSUE_TEMPLATE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
	  AND ISSUE_TEMPLATE_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL
	  AND ISSUE_TEMPLATE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL
	  AND ISSUE_TEMPLATE_ID IS NULL)
	OR
	(ACTION_TYPE = 'issue' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL
	  AND ISSUE_TEMPLATE_ID IS NOT NULL)
);
ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_QSEA_ISS_TEMP 
	FOREIGN KEY (APP_SID, ISSUE_TEMPLATE_ID)
	REFERENCES CSR.ISSUE_TEMPLATE (APP_SID, ISSUE_TEMPLATE_ID) ON DELETE CASCADE;
ALTER TABLE CSR.ISSUE_TEMPLATE ADD CONSTRAINT FK_IT_ISSUE_TYPE
	FOREIGN KEY (APP_SID, ISSUE_TYPE_ID)
	REFERENCES CSR.ISSUE_TYPE (APP_SID, ISSUE_TYPE_ID);
ALTER TABLE CSR.ISSUE_TEMPLATE ADD CONSTRAINT FK_IT_ASSIGN_TO_USER
	FOREIGN KEY (APP_SID, ASSIGN_TO_USER_SID)
	REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);
ALTER TABLE CSR.ISSUE_TEMPLATE_CUSTOM_FIELD ADD CONSTRAINT FK_ITCF_ISS_TEMP
	FOREIGN KEY (APP_SID, ISSUE_TEMPLATE_ID)
	REFERENCES CSR.ISSUE_TEMPLATE (APP_SID, ISSUE_TEMPLATE_ID) ON DELETE CASCADE;
ALTER TABLE CSR.ISSUE_TEMPLATE_CUSTOM_FIELD ADD CONSTRAINT FK_ITCF_CUS_FIELD
	FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID)
	REFERENCES CSR.ISSUE_CUSTOM_FIELD (APP_SID, ISSUE_CUSTOM_FIELD_ID);
ALTER TABLE CSR.ISSUE_TEMPLATE_CUST_FIELD_OPT ADD CONSTRAINT FK_ITCFO_ISS_TEMP
	FOREIGN KEY (APP_SID, ISSUE_TEMPLATE_ID)
	REFERENCES CSR.ISSUE_TEMPLATE (APP_SID, ISSUE_TEMPLATE_ID) ON DELETE CASCADE;
ALTER TABLE CSR.ISSUE_TEMPLATE_CUST_FIELD_OPT ADD CONSTRAINT FK_ITCFO_CUST_FIELD_OPT
	FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID)
	REFERENCES CSR.ISSUE_CUSTOM_FIELD_OPTION (APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_CUSTOM_FIELD_OPT_ID);
DELETE FROM surveys.answer_file;
DELETE FROM surveys.submission_file;
DROP INDEX SURVEYS.IX_ANS_FILE_SUB_ID;
DROP SEQUENCE surveys.SURVEY_ANSWER_FILE_ID_SEQ;
ALTER TABLE surveys.submission_file ADD submission_file_id NUMBER(10) NOT NULL;
ALTER TABLE surveys.answer_file ADD submission_file_id NUMBER(10) NOT NULL;
ALTER TABLE surveys.answer_file DROP CONSTRAINT PK_SURVEY_ANSWER_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT FK_ANS_FILE_SUB_ID;
ALTER TABLE surveys.answer_file DROP CONSTRAINT FK_ANSWER_FILE_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT UK_SURVEY_ANSWER_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT UK_SURVEYS_ANSWER_FILE_A;
ALTER TABLE surveys.submission_file DROP CONSTRAINT PK_SUBMISSION_FILE;
ALTER TABLE surveys.answer_file DROP COLUMN answer_file_id;
ALTER TABLE surveys.answer_file DROP COLUMN submission_id;
ALTER TABLE surveys.answer_file DROP COLUMN filename;
ALTER TABLE surveys.answer_file DROP COLUMN uri;
ALTER TABLE surveys.submission_file ADD CONSTRAINT PK_SUBMISSION_FILE
	PRIMARY KEY (APP_SID, SUBMISSION_FILE_ID);
ALTER TABLE surveys.answer_file ADD CONSTRAINT PK_SURVEY_ANSWER_FILE
	PRIMARY KEY (APP_SID, ANSWER_ID, SUBMISSION_FILE_ID);
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_FILE
	FOREIGN KEY (APP_SID, SUBMISSION_FILE_ID)
	REFERENCES SURVEYS.SUBMISSION_FILE(APP_SID, SUBMISSION_FILE_ID)
;
CREATE SEQUENCE surveys.survey_submission_file_id_seq;
ALTER TABLE csr.score_type ADD show_expired_scores NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.score_type ADD CONSTRAINT chk_score_type_show_exp CHECK (show_expired_scores IN (0, 1));
ALTER TABLE csrimp.score_type ADD show_expired_scores NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.score_type ADD CONSTRAINT chk_score_type_show_exp CHECK (show_expired_scores IN (0, 1));
UPDATE csr.score_type SET show_expired_scores = 1;
ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT chk_sup_rel_dtm_valid CHECK ((valid_until_dtm IS NULL) OR (set_dtm <= valid_until_dtm));
ALTER TABLE chain.supplier_relationship_score DROP CONSTRAINT uk_supplier_relationship_score;
ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT uk_supplier_relationship_score UNIQUE (purchaser_company_sid, supplier_company_sid, score_type_id, set_dtm, is_override);


GRANT SELECT ON CSR.MEASURE_CONVERSION TO SURVEYS;
grant select, insert, update, delete on csrimp.issue_template to tool_user;
grant select, insert, update, delete on csrimp.issue_template_custom_field to tool_user;
grant select, insert, update, delete on csrimp.issue_template_cust_field_opt to tool_user;
grant select, insert, update on csr.issue_template to csrimp;
grant select, insert, update on csr.issue_template_custom_field to csrimp;
grant select, insert, update on csr.issue_template_cust_field_opt to csrimp;
grant select on csr.issue_template_id_seq to csrimp;


ALTER TABLE SURVEYS.SUBMISSION_FILE ADD CONSTRAINT FK_SUB_FILE_CUSTOMER
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_CUSTOMER
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;
ALTER TABLE SURVEYS.SUBMISSION_FILE ADD CONSTRAINT FK_SUB_FILE_UPLOADED_USER
	FOREIGN KEY (APP_SID, UPLOADED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;


UPDATE csr.issue_type 
   SET helper_pkg = 'csr.permit_pkg' 
 WHERE issue_type_id = 22;
UPDATE surveys.answer 
   SET hidden = 0
 WHERE hidden IS NULL;
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang, qv.option_data_source_id, q.lookup_key
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;
	 
CREATE OR REPLACE VIEW chain.v$current_raw_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND is_override = 0
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 0
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		)
;
CREATE OR REPLACE VIEW chain.v$current_ovr_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND is_override = 1
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 1
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		)
;
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score_all AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   MAX(supplier_relationship_score_id) raw_sup_relationship_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   MAX(valid) raw_valid, 
		   --
		   MAX(ovr_sup_relationship_score_id) ovr_sup_relationship_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id, 
		   MAX(valid) ovr_valid
	  FROM (
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, valid,
				   --
				   NULL ovr_sup_relationship_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id, NULL ovr_valid
			  FROM chain.v$current_raw_sup_rel_score
			  UNION ALL
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   NULL supplier_relationship_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, NULL valid,
				   --
				   supplier_relationship_score_id ovr_sup_relationship_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override, set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, 
				   changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, score_source_id ovr_score_source_id, valid ovr_valid
			  FROM chain.v$current_ovr_sup_rel_score
	)
	GROUP BY supplier_company_sid, purchaser_company_sid, score_type_id
; 
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score_threshold_id, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_id, raw_score_source_id) score_source_id, 
		   NVL2(ovr_score_threshold_id, ovr_valid, raw_valid) valid
	  FROM v$current_sup_rel_score_all
;




BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (40, 'Set calc end of time window', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the number of years to bound calculation "end of time"', 'SetCalcFutureWindow', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (40, 'Number of years', 'How far forward should calculations extend', 0, 1, 0);
END;
/
BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.REFRESH_CALC_WINDOWS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.customer_pkg.RefreshCalcWindows; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1), 'YYYY/MM/DD') || ' 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1;BYHOUR=02;BYMINUTE=00;BYSECOND=00',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Refresh calculation start/end time window for all customers'
	);
END;
/
BEGIN
	security.user_pkg.logonadmin;
	DELETE FROM surveys.answer_option
	 WHERE answer_id IN (
		SELECT answer_id
		  FROM surveys.answer
		 WHERE repeat_index IS NULL
		   AND question_id IN (
	  		SELECT question_id
	  		  FROM surveys.question
	  		 WHERE matrix_parent_id IN(
				SELECT question_id
				  FROM surveys.question
				 WHERE question_type = 'matrixdynamic' 
			)
		)
	);
	DELETE FROM surveys.answer
	 WHERE repeat_index IS NULL
	   AND question_id IN (
  		SELECT question_id
  		  FROM surveys.question
  		 WHERE matrix_parent_id IN(
				SELECT question_id
				  FROM surveys.question
				 WHERE question_type = 'matrixdynamic' 
			)
		);
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (41, 'Set calc start of time date', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the earliest date to include for calculations', 'SetCalcStartDate', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (41, 'Calc start date (YYYY-MM-DD)', 'Date in YYYY-MM-DD format e.g.2010-01-01', 0, NULL, 0);
END;
/
UPDATE csr.std_factor
   SET std_measure_conversion_id = 19
 WHERE std_factor_set_id = 1454
   AND factor_type_id = 13995
   AND std_measure_conversion_id = 38;
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE surveys.question
	   SET measure_sid = NULL
	 WHERE measure_sid = -1;
END;
/






--@..\surveys\question_library_pkg
@..\audit_pkg
@..\csr_data_pkg
@..\meter_pkg
--@..\surveys\integration_pkg
@..\customer_pkg
@..\util_script_pkg
--@..\surveys\survey_pkg
@..\quick_survey_pkg
@..\schema_pkg


--@..\surveys\question_library_body
@..\audit_body
@..\schema_body
@..\csrimp\imp_body
--@..\surveys\survey_body
@..\meter_body
--@..\surveys\integration_body
@..\csr_app_body
@..\customer_body
@..\util_script_body
@..\aggregate_ind_body
@..\enable_body
@..\region_body
@..\imp_body
@..\chain\supplier_audit_body
@..\initiative_report_body
@..\quick_survey_body
--@..\surveys\survey_body.sql
@..\chain\company_body.sql
@..\chain\company_filter_body.sql
@..\supplier_body.sql
@..\schema_body.sql
@..\csrimp\imp_body.sql



@update_tail
