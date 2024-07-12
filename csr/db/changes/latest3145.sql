define version=3145
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
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CMS.PAGED_TT_ID
( 
	ID							NUMBER(10) NOT NULL
) 
ON COMMIT DELETE ROWS; 
CREATE UNIQUE INDEX CMS.UK_PAGED_TT_ID ON CMS.PAGED_TT_ID (ID);

-- Alter tables
ALTER TABLE csr.flow_item ADD (
	region_sid			NUMBER(10),
	CONSTRAINT fk_flow_item_region FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid)
);

CREATE INDEX csr.ix_flow_item_region ON csr.flow_item (app_sid, region_sid);

ALTER TABLE csrimp.flow_item ADD (
	region_sid			NUMBER(10)
);

ALTER TABLE cms.tab ADD (
	storage_location	VARCHAR2(255) DEFAULT 'oracle' NOT NULL
);

ALTER TABLE csrimp.cms_tab ADD (
	storage_location	VARCHAR2(255) NOT NULL
);
CREATE TABLE SURVEYS.QUESTION_CALC_EXPR_REF
(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		NOT NULL,
	REFERENCE_QUESTION_ID		NUMBER(10, 0)	NOT NULL,
	POS							NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	DELETED						NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QCEQ_DELETED_0_1 CHECK (DELETED IN (0,1)),
	CONSTRAINT PK_QUESTION_CALC_EXPR_REF_REF PRIMARY KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, REFERENCE_QUESTION_ID, POS),
	CONSTRAINT FK_QUESTION_CALC_EXPR_Q_VERS FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
		REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT),
	CONSTRAINT FK_QUESTION_CALC_EXPR_REF_Q FOREIGN KEY (APP_SID, REFERENCE_QUESTION_ID)
		REFERENCES SURVEYS.QUESTION(APP_SID, QUESTION_ID)
);
CREATE TABLE SURVEYS.SECTION_TEMPLATE(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	CREATED_DTM				TIMESTAMP		DEFAULT SYSTIMESTAMP NOT NULL,
	CREATED_USER_SID		NUMBER(10, 0)	NOT NULL,
	LAST_UPDATED_DTM		TIMESTAMP,
	LAST_UPDATED_USER_SID	NUMBER(10, 0),
	CONSTRAINT PK_SECTION_TEMPLATE PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID)
)
;
CREATE TABLE SURVEYS.SECTION_TEMPLATE_TR(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	LANGUAGE_CODE			VARCHAR2(50)	NOT NULL,
	NAME					VARCHAR2(4000)	NOT NULL,
	CONSTRAINT PK_SECTION_TEMPLATE_TR PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID, LANGUAGE_CODE),
	CONSTRAINT FK_SECTION_TEMPLATE_TR_ST FOREIGN KEY (APP_SID, SECTION_TEMPLATE_ID)
		REFERENCES SURVEYS.SECTION_TEMPLATE (APP_SID, SECTION_TEMPLATE_ID)
)
;
CREATE TABLE SURVEYS.SECTION_TEMPLATE_SECTION(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	SECTION_ID				NUMBER(10, 0)	NOT NULL,
	PARENT_ID				NUMBER(10, 0),
	POS						NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SECTION_TEMPLATE_SECTION PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID),
	CONSTRAINT FK_SECTION_TEMPL_SECT_PARENT FOREIGN KEY (APP_SID, SECTION_TEMPLATE_ID, PARENT_ID)
		REFERENCES SURVEYS.SECTION_TEMPLATE_SECTION (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID)
)
;
CREATE TABLE SURVEYS.SECTION_TEMPLATE_SECTION_TR(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	SECTION_ID				NUMBER(10, 0)	NOT NULL,
	LANGUAGE_CODE			VARCHAR2(50)	NOT NULL,
	LABEL					VARCHAR2(1024),
	SIMPLE_INFO_TEXT		VARCHAR2(4000),
	POPUP_TEXT				VARCHAR2(4000),
	CONSTRAINT PK_SECTION_TEMPLATE_SECT_TR PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID, LANGUAGE_CODE),
	CONSTRAINT FK_SECTION_TEMPLATE_SECT_ID FOREIGN KEY (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID)
		REFERENCES SURVEYS.SECTION_TEMPLATE_SECTION (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID)
)
;
CREATE TABLE SURVEYS.SECTION_TEMPLATE_SECTION_TAG(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	SECTION_ID				NUMBER(10, 0)	NOT NULL,
	TAG_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SECTION_TEMPLATE_SECT_TAG PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID, TAG_ID)
)
;
CREATE TABLE SURVEYS.SECTION_TEMPLATE_QUESTION(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_TEMPLATE_ID		NUMBER(10, 0)	NOT NULL,
	SECTION_ID				NUMBER(10, 0)	NOT NULL,
	QUESTION_ID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SECTION_TEMPLATE_SECT_QUEST PRIMARY KEY (APP_SID, SECTION_TEMPLATE_ID, SECTION_ID, QUESTION_ID),
	CONSTRAINT FK_SECTION_TEMPLATE_SECT_QUEST FOREIGN KEY (APP_SID, QUESTION_ID)
		REFERENCES SURVEYS.QUESTION (APP_SID, QUESTION_ID)
)
;
CREATE SEQUENCE SURVEYS.SECTION_TEMPLATE_SEQ;
CREATE TABLE CSR.FLOW_ITEM_REGION(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_ITEM_ID					NUMBER(10, 0)	NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_ITEM_REGION PRIMARY KEY (APP_SID, FLOW_ITEM_ID, REGION_SID)
)
;
ALTER TABLE CSR.FLOW_ITEM_REGION ADD CONSTRAINT FK_FLOW_ITEM_REGION_FLOW_ITEM
	FOREIGN KEY (APP_SID, FLOW_ITEM_ID) 
	REFERENCES CSR.FLOW_ITEM (APP_SID, FLOW_ITEM_ID)
;
ALTER TABLE CSR.FLOW_ITEM_REGION ADD CONSTRAINT FK_FLOW_ITEM_REGION_REGION 
	FOREIGN KEY (APP_SID, REGION_SID) 
	REFERENCES CSR.REGION (APP_SID, REGION_SID)
;
BEGIN
	security.user_pkg.LogonAdmin;
	INSERT INTO csr.flow_item_region (app_sid, flow_item_id, region_sid) 
	SELECT app_sid, flow_item_id, region_sid
	  FROM csr.flow_item
	 WHERE region_sid IS NOT NULL;
	 
	INSERT INTO csr.flow_item_region (app_sid, flow_item_id, region_sid) 
	SELECT app_sid, flow_item_id, region_sid
	  FROM surveys.response
	 WHERE flow_item_id IS NOT NULL 
	   AND region_sid IS NOT NULL;
END;
/
ALTER TABLE CSR.FLOW_ITEM DROP CONSTRAINT FK_FLOW_ITEM_REGION;
ALTER TABLE CSR.FLOW_ITEM DROP COLUMN REGION_SID;
CREATE INDEX CSR.IX_FLOW_ITEM_REG_REGION_SID ON CSR.FLOW_ITEM_REGION (APP_SID, REGION_SID);
CREATE TABLE CSRIMP.FLOW_ITEM_REGION (
	CSRIMP_SESSION_ID				        NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_ITEM_ID                            NUMBER(10, 0)    NOT NULL,
    REGION_SID                              NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_ITEM_REGION PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_ITEM_ID, REGION_SID),
    CONSTRAINT FK_FLOW_ITEM_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


ALTER TABLE SURVEYS.QUESTION_VERSION ADD
(
	CALCULATION_EXPRESSION		CLOB
);
ALTER TABLE SURVEYS.SECTION_TEMPLATE_TR
	ADD CONSTRAINT SECTION_TEMPLATE_NAME_UNIQUE UNIQUE (APP_SID, LANGUAGE_CODE, NAME)
;
CREATE UNIQUE INDEX CSR.IDX_USER_PROFILE_PK ON CSR.USER_PROFILE(APP_SID, UPPER(PRIMARY_KEY))
;
ALTER TABLE cms.tab ADD (
	managed_version					NUMBER(10)
);
UPDATE cms.tab
   SET managed_version = 1
 WHERE managed = 1;
 
ALTER TABLE cms.tab ADD (
	CONSTRAINT chk_mngd_version CHECK (managed = 1 AND managed_version IS NOT NULL OR managed = 0)
);
ALTER TABLE csrimp.cms_tab ADD (
	managed_version					NUMBER(10),
	CONSTRAINT chk_mngd_version CHECK (managed = 1 AND managed_version IS NOT NULL OR managed = 0)
);
ALTER TABLE CSR.CUSTOMER DROP COLUMN TPLREPORTPERIODEXTENSION;
ALTER TABLE CSR.CUSTOMER DROP COLUMN DATA_EXPLORER_PERIOD_EXTENSION;
ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN TPLREPORTPERIODEXTENSION;
ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN DATA_EXPLORER_PERIOD_EXTENSION;
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD 
(
	IS_SUBMISSION NUMBER(1) DEFAULT 0 NOT NULL,
	FLOW_STATE_LOG_ID NUMBER(10),
	FLOW_STATE_TRANSITION_ID NUMBER(10),
	TRANSITION_OCCURRENCE_ID VARCHAR2(50),
	CONSTRAINT CHK_RS_IS_SUBMISSION CHECK (IS_SUBMISSION IN (0,1))
);
ALTER TABLE SURVEYS.SECTION_TEMPLATE MODIFY (CREATED_DTM DATE DEFAULT SYSDATE);
ALTER TABLE SURVEYS.SECTION_TEMPLATE MODIFY (LAST_UPDATED_DTM DATE);


GRANT SELECT ON csr.flow_item TO surveys;
GRANT SELECT ON csr.flow_state TO surveys;
GRANT SELECT ON csr.flow_state_survey_tag TO surveys;
GRANT SELECT ON chain.v$current_country_risk_level TO CSR;
grant references on csr.flow_state_log to surveys;
grant references on csr.flow_state_transition to surveys;
grant insert, update, select on csr.flow_item_region to csrimp;
REVOKE SELECT ON csr.flow_item FROM surveys;
REVOKE SELECT ON csr.flow_state FROM surveys;
REVOKE SELECT ON csr.flow_state_survey_tag FROM surveys;




CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id, qv.lookup_key
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id AND sq.question_version = qv.question_version
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;




BEGIN
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('calculation', 'Calculation');
END;
/
BEGIN
	INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
		 VALUES (42, 'Remove matrix layout settings from a delegation', 'Removes layout settings from a delegation. See wiki for details.', 'RemoveMatrixLayout', 'W2866');
	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
		 VALUES (42, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);
	INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
		 VALUES (43, 'Create unique copy of matrix layout for delegation', 'Creates a unique copy of a matrix layout. Use this if you have copied a delegation that has a matrix layout. See wiki for details.', 'CreateUniqueMatrixLayoutCopy', 'W2866');
	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
		 VALUES (43, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);
END;
/
INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
			values(15887, 13968, 'Road Vehicle Distance - Car (Small) - Gasoline / Petrol Hybrid (Direct)', 10, 0);
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE SURVEYS.RESPONSE_SUBMISSION
	   SET IS_SUBMISSION = 1
	 WHERE SUBMITTED_DTM IS NOT NULL;
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) 
		VALUES (37, 'campaign', 'Promoted to Submission'); 
END;
/

create or replace package csr.form_data_pkg as
end;
/
grant execute on csr.form_data_pkg to web_user;

CREATE OR REPLACE PACKAGE surveys.template_pkg AS END;
/
GRANT EXECUTE ON surveys.template_pkg to web_user;


--@..\surveys\question_library_pkg
--@..\surveys\survey_pkg
--@..\surveys\template_pkg
@..\util_script_pkg
@..\..\..\aspen2\cms\db\tab_pkg
--@..\surveys\integration_pkg
@..\csr_data_pkg
@..\unit_test_pkg
@..\indicator_pkg
@..\scenario_pkg
@..\region_pkg
@..\flow_pkg
@..\schema_pkg
@..\chain\company_pkg
@..\audit_pkg
@..\chain\supplier_flow_pkg
@..\chain\card_pkg
@..\chain\plugin_pkg
@..\form_data_pkg


--@..\surveys\survey_body
--@..\surveys\condition_body
--@..\surveys\question_library_body
--@..\surveys\template_body
@..\util_script_body
@..\..\..\aspen2\cms\db\tab_body
@..\audit_body
--@..\surveys\integration_body
@..\csr_data_body
@..\approval_dashboard_body
@..\user_profile_body
@..\property_body
@..\..\..\aspen2\cms\db\filter_body
@..\unit_test_body
@..\csrimp\imp_body
@..\indicator_body
@..\scenario_body
@..\region_body
@..\customer_body
@..\schema_body
@..\flow_body
@..\form_data_body
@..\quick_survey_body
@..\chain\company_body
@..\issue_body
@..\chain\supplier_flow_body
@..\chain\card_body
@..\chain\plugin_body
@..\chain\business_relationship_body
@..\chain\company_filter_body
@..\chain\dashboard_body
@..\chain\type_capability_body



@update_tail
