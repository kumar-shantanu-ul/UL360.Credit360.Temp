define version=3096
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

CREATE TABLE csr.score_type_audit_type (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	score_type_id				NUMBER(10, 0)	NOT NULL,
	internal_audit_type_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_score_type_audit_type PRIMARY KEY (app_sid, score_type_id, internal_audit_type_id)
)
;
CREATE TABLE csrimp.score_type_audit_type (
	csrimp_session_id			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	score_type_id				NUMBER(10, 0)	NOT NULL,
	internal_audit_type_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_score_type_audit_type PRIMARY KEY (csrimp_session_id, score_type_id, internal_audit_type_id)
)
;
create index csr.ix_score_type_au_internal_audi on csr.score_type_audit_type (app_sid, internal_audit_type_id);

DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = 'SURVEYS';
	IF v_exists <> 0 THEN
		EXECUTE IMMEDIATE 'DROP USER SURVEYS CASCADE';
	END IF;
END;
/
CREATE USER SURVEYS IDENTIFIED BY surveys QUOTA UNLIMITED ON USERS;
DECLARE
	v_class_id 		security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'Surveys', 'surveys.survey_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/
CREATE SEQUENCE SURVEYS.QUESTION_ID_SEQ;
CREATE TABLE SURVEYS.QUESTION_TYPE(
	QUESTION_TYPE				VARCHAR2(20)	NOT NULL,
	LABEL						VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_QUESTION_TYPE PRIMARY KEY (QUESTION_TYPE)
)
;
CREATE TABLE SURVEYS.QUESTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_TYPE				VARCHAR2(20)	NOT NULL,
	LOOKUP_KEY					VARCHAR2(255),
	MAPS_TO_IND_SID				NUMBER(10, 0),
	MEASURE_SID					NUMBER(10, 0),
	LATEST_QUESTION_VERSION		NUMBER(10)		NOT NULL,
	LATEST_QUESTION_DRAFT		NUMBER(1)		NOT NULL,
	MATRIX_PARENT_ID			NUMBER(10, 0),
	MATRIX_PARENT_VERSION		NUMBER(10, 0),
	MATRIX_PARENT_DRAFT			NUMBER(1, 0),
	CONSTRAINT PK_QUESTION PRIMARY KEY (APP_SID, QUESTION_ID),
	CONSTRAINT FK_QUESTION_VERSION_PARENT FOREIGN KEY (APP_SID, MATRIX_PARENT_ID) REFERENCES SURVEYS.QUESTION(APP_SID, QUESTION_ID),
	CONSTRAINT FK_QUESTION_QUESTION_TYPE FOREIGN KEY (QUESTION_TYPE) REFERENCES SURVEYS.QUESTION_TYPE(QUESTION_TYPE),
	CONSTRAINT CONS_QUESTION_MEASURE UNIQUE (APP_SID, QUESTION_ID, MEASURE_SID),
	CONSTRAINT CHK_QV_MATRIX_PARENT_DRAFT CHECK (MATRIX_PARENT_DRAFT IN (NULL,0,1))
)
;
CREATE INDEX SURVEYS.IX_LATEST_QUESTION_VERSION ON SURVEYS.QUESTION(APP_SID, QUESTION_ID, LATEST_QUESTION_VERSION, LATEST_QUESTION_DRAFT);
CREATE UNIQUE INDEX SURVEYS.IX_QUESTION_LOOKUP_KEY ON SURVEYS.QUESTION(CASE WHEN LOOKUP_KEY IS NOT NULL THEN APP_SID END, LOOKUP_KEY);
CREATE TABLE SURVEYS.QUESTION_VERSION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 1 NOT NULL,
	MATRIX_CHILD_POS			NUMBER(5),
	MANDATORY					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	DEFAULT_NUMERIC_VALUE		NUMBER(20, 10),
	CHARACTER_LIMIT				NUMBER(4, 0),
	MIN_NUMERIC_VALUE			NUMBER(14, 4),
	MAX_NUMERIC_VALUE			NUMBER(14, 4),
	NUMERIC_VALUE_TOLERANCE		NUMBER(13, 10),
	DECIMAL_PLACES				NUMBER(2, 0),
	MIN_SELECTIONS				NUMBER(4, 0),
	MAX_SELECTIONS				NUMBER(4, 0),
	DISPLAY_TYPE				VARCHAR2(50),
	VALUE_VALIDATION_TYPE		VARCHAR2(50),
	COMMENTS_DISPLAY_TYPE		VARCHAR2(50),
	REMEMBER_ANSWER				NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	COUNT_TOWARDS_PROGRESS		NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ALLOW_FILE_UPLOADS			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ALLOW_USER_COMMENTS			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	MATCH_EVERY_CATEGORY		NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	DETAILED_HELP_LINK			VARCHAR2(1000),
	ACTION						VARCHAR2(50),
	LAST_MODIFIED_DTM			DATE			DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_QUESTION_VERSION PRIMARY KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT),
	CONSTRAINT FK_QUESTION_VERSION_QUESTION FOREIGN KEY (APP_SID, QUESTION_ID) REFERENCES SURVEYS.QUESTION(APP_SID, QUESTION_ID),
	CONSTRAINT CHK_QV_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1)),
	CONSTRAINT CHK_QV_MANDATORY_0_1 CHECK (MANDATORY IN (0,1)),
	CONSTRAINT CHK_QV_REM_ANSWER_0_1 CHECK (REMEMBER_ANSWER IN (0,1)),
	CONSTRAINT CHK_QV_COUNT_PROG_0_1 CHECK (COUNT_TOWARDS_PROGRESS IN (0,1)),
	CONSTRAINT CHK_QV_ALLOW_UPLOADS_0_1 CHECK (ALLOW_FILE_UPLOADS IN (0,1)),
	CONSTRAINT CHK_QV_ALLOW_COMMS_0_1 CHECK (ALLOW_USER_COMMENTS IN (0,1)),
	CONSTRAINT CHK_QV_MATCH_EVERY_CAT_0_1 CHECK (MATCH_EVERY_CATEGORY IN (0,1))
)
;
CREATE TABLE SURVEYS.QUESTION_OPTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_OPTION_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		NOT NULL,
	POS							NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	LOOKUP_KEY					VARCHAR2(1000),
	IS_DEFAULT					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ENDS_SURVEY					NUMBER(1, 0),
	GROUPING_PATH				VARCHAR2(1000),
	MAPS_TO_IND_SID				NUMBER(10, 0),
	OPTION_ACTION				VARCHAR2(50),
	CONSTRAINT PK_QUESTION_OPTION PRIMARY KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT),
	CONSTRAINT CHK_QO_IS_DEFAULT_0_1 CHECK (IS_DEFAULT IN (0,1)),
	CONSTRAINT CHK_QO_ENDS_SURVEY_0_1 CHECK (ENDS_SURVEY IN (NULL, 0,1))
)
;
CREATE SEQUENCE SURVEYS.QUESTION_OPTION_ID_SEQ;
CREATE TABLE SURVEYS.QUESTION_OPTION_TAG(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	QUESTION_OPTION_ID			NUMBER(10, 0)	NOT NULL,
	TAG_ID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_QUESTION_OPTION_TAG PRIMARY KEY (APP_SID, QUESTION_OPTION_ID, TAG_ID)
)
;
CREATE TABLE SURVEYS.QUESTION_TAG(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 0 NOT NULL,
	TAG_ID						NUMBER(10, 0)	NOT NULL,
	SHOW_IN_SURVEY				NUMBER(1, 0)	DEFAULT 0 NOT NULL,	
	CONSTRAINT PK_QUESTION_TAG PRIMARY KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, TAG_ID),
	CONSTRAINT CHK_QT_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1)),
	CONSTRAINT CHK_QT_SHOW_IN_SURVEY CHECK (SHOW_IN_SURVEY IN (0,1))
)
;
CREATE TABLE SURVEYS.SURVEY_VERSION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	PARENT_SID					NUMBER(10, 0)	NOT NULL,
	CREATED_DTM					DATE			DEFAULT SYSDATE NOT NULL,
	LAST_MODIFIED_DTM			DATE			NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	START_DTM					DATE,
	END_DTM						DATE,
	PUBLISHED_DTM				DATE,
	PUBLISHED_BY_SID			NUMBER(10, 0),
	CONSTRAINT PK_SURVEY_VERSION PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
)
;
CREATE TABLE SURVEYS.SURVEY_SECTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	SECTION_ID					NUMBER(10, 0)	NOT NULL,
	PARENT_ID					NUMBER(10, 0)	NULL,
	POS							NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SURVEY_QUESTION PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID),
	CONSTRAINT FK_SURVEY_SECTION_PARENT FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, PARENT_ID) REFERENCES SURVEYS.SURVEY_SECTION(APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
)
;
CREATE SEQUENCE SURVEYS.SURVEY_SECTION_ID_SEQ;
CREATE TABLE SURVEYS.SURVEY_SECTION_TAG(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	SECTION_ID					NUMBER(10, 0)	NOT NULL,
	TAG_ID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SURVEY_SECTION_TAG PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID, TAG_ID)
)
;
CREATE TABLE SURVEYS.SURVEY_SECTION_QUESTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	SECTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 0 NOT NULL,
	POS							NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SURVEY_SECTION_QUESTION PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, QUESTION_ID)
)
;
CREATE SEQUENCE SURVEYS.SURVEY_QUESTION_ID_SEQ;
CREATE TABLE SURVEYS.LANGUAGE(
	LANGUAGE_CODE				VARCHAR2(50)	NOT NULL,
	CONSTRAINT PK_SURVEY_LANGUAGE PRIMARY KEY (LANGUAGE_CODE)
)
;
CREATE TABLE SURVEYS.QUESTION_VERSION_TR(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 0 NOT NULL,
	LANGUAGE_CODE				VARCHAR2(50)	NOT NULL,
	LABEL						VARCHAR2(4000),
	DEFAULT_STRING_VALUE		VARCHAR2(4000),
	SIMPLE_HELP					VARCHAR2(4000),
	POPUP_HELP					VARCHAR2(4000),
	DETAILED_HELP				VARCHAR2(4000),
	CONSTRAINT PK_QUESTION_VERSION_TR PRIMARY KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, LANGUAGE_CODE),
	CONSTRAINT CHK_QV_TR_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1))
)
;
CREATE TABLE SURVEYS.QUESTION_OPTION_TR(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	QUESTION_OPTION_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_ID					NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION			NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		NOT NULL,
	LANGUAGE_CODE				VARCHAR2(50)	NOT NULL,
	LABEL						VARCHAR2(4000)	NOT NULL,
	TOOLTIP						VARCHAR2(1000),
	CONSTRAINT PK_QUESTION_OPTION_TR PRIMARY KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, LANGUAGE_CODE),
	CONSTRAINT CHK_OP_TR_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1))
)
;
CREATE TABLE SURVEYS.SURVEY_VERSION_TR(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	LANGUAGE_CODE				VARCHAR2(50)	NOT NULL,
	LABEL						VARCHAR2(1024)	NOT NULL,
	CONSTRAINT PK_SURVEY_VERSION_TR PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, LANGUAGE_CODE)
)
;
CREATE TABLE SURVEYS.SURVEY_SECTION_TR(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	SECTION_ID					NUMBER(10, 0)	NOT NULL,
	LABEL						VARCHAR(1024)	NOT NULL,
	SIMPLE_HELP					VARCHAR2(4000),
	DETAILED_HELP				VARCHAR2(4000),
	LANGUAGE_CODE				VARCHAR2(50)	NOT NULL,
	CONSTRAINT PK_SURVEY_SECTION_TR PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID, LANGUAGE_CODE)
)
;
ALTER TABLE SURVEYS.QUESTION ADD CONSTRAINT FK_LATEST_QUESTION_VERSION
	FOREIGN KEY (APP_SID, QUESTION_ID, LATEST_QUESTION_VERSION, LATEST_QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)	DEFERRABLE INITIALLY DEFERRED
;
ALTER TABLE SURVEYS.QUESTION_TAG ADD CONSTRAINT FK_QUESTION_TAG_QV
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_QUESTION ADD CONSTRAINT FK_SURVEY_SECTION_QUESTION_SS
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
	REFERENCES SURVEYS.SURVEY_SECTION(APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_TAG ADD CONSTRAINT FK_SURVEY_SECTION_TAG_SS
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
	REFERENCES SURVEYS.SURVEY_SECTION(APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_TAG ADD CONSTRAINT FK_SURVEY_SECTION_TAG_SV
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION(APP_SID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_QUESTION ADD CONSTRAINT FK_SURVEY_SECTION_QUESTION_SV
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION(APP_SID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE SURVEYS.QUESTION_VERSION_TR ADD CONSTRAINT FK_QUESTON_VERSN_TR_VERSN
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;
ALTER TABLE SURVEYS.QUESTION_OPTION_TR ADD CONSTRAINT FK_QUESTON_OP_TR_OPTION
	FOREIGN KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_OPTION(APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;
ALTER TABLE SURVEYS.SURVEY_VERSION_TR ADD CONSTRAINT FK_SURVEY_VERSION_TR_VERSN
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION(APP_SID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD CONSTRAINT FK_SURVEY_SECTION_TR_SECTION
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
	REFERENCES SURVEYS.SURVEY_SECTION(APP_SID, SURVEY_SID, SURVEY_VERSION, SECTION_ID)
;
CREATE TABLE csr.comp_permit_sched_issue (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_pmt_reg_sched_issue PRIMARY KEY (app_sid, flow_item_id, issue_scheduled_task_id),	
	CONSTRAINT fk_cmp_pmt_schd_iss_flow_item FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.flow_item (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_pmt_schd_iss_iss_sched FOREIGN KEY (app_sid, issue_scheduled_task_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);
create index csr.ix_comp_permit_s_issue_schedul on csr.comp_permit_sched_issue (app_sid, issue_scheduled_task_id);


ALTER TABLE csr.auto_imp_core_data_settings
ADD date_string_exact_parse_format VARCHAR2(255);
ALTER TABLE CSR.AUTO_EXP_RETRIEVAL_DATAVIEW ADD (MAPPING_XML SYS.XMLType);
ALTER TABLE csr.compliance_options ADD (
	permit_score_type_id NUMBER(10),
	CONSTRAINT FK_COMP_OPT_PERM_SCORE_TYPE FOREIGN KEY (app_sid, permit_score_type_id) REFERENCES csr.score_type(app_sid, score_type_id)
);
CREATE INDEX csr.ix_comp_op_perm_score_type_id ON csr.compliance_options (app_sid, permit_score_type_id);
ALTER TABLE csrimp.compliance_options ADD (
	permit_score_type_id NUMBER(10)
);
ALTER TABLE csr.score_type_audit_type ADD CONSTRAINT fk_score_typ_aud_typ_aud_typ
	FOREIGN KEY (app_sid, internal_audit_type_id)
	REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
;
ALTER TABLE csr.score_type_audit_type ADD CONSTRAINT fk_score_typ_aud_typ_score_typ
	FOREIGN KEY (app_sid, score_type_id)
	REFERENCES csr.score_type (app_sid, score_type_id)
;
ALTER TABLE csrimp.score_type_audit_type ADD CONSTRAINT fk_score_type_audit_type_is 
	FOREIGN KEY (csrimp_session_id)
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
;
create index surveys.ix_question_matrix_parent on surveys.question (app_sid, matrix_parent_id);
create index surveys.ix_question_maps_to_ind_s on surveys.question (app_sid, maps_to_ind_sid, measure_sid);
create index surveys.ix_question_opti_language_code on surveys.question_option_tr (language_code);
create index surveys.ix_question_vers_language_code on surveys.question_version_tr (language_code);
create index surveys.ix_survey_s_survey_sid_su on surveys.survey_section (app_sid, survey_sid, survey_version, parent_id);
create index surveys.ix_survey_sq_survey_sid_su on surveys.survey_section_question (app_sid, survey_sid, survey_version, section_id);
create index surveys.ix_survey_sectio_language_code on surveys.survey_section_tr (language_code);
create index surveys.ix_survey_versio_language_code on surveys.survey_version_tr (language_code);
ALTER TABLE chain.tt_user_details ADD USER_NAME VARCHAR2(256);
ALTER TABLE chain.customer_options ADD allow_duplicate_emails NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_allow_dup_emails CHECK (allow_duplicate_emails IN (0, 1));
ALTER TABLE csrimp.chain_customer_options ADD allow_duplicate_emails NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_allow_dup_emails CHECK (allow_duplicate_emails IN (0, 1));
ALTER TABLE chain.tt_filter_date_range 
  ADD NULL_FILTER NUMBER(10) DEFAULT 0 NOT NULL; 
ALTER TABLE csr.issue ADD (
	notified_overdue NUMBER(1) DEFAULT 0,
	CONSTRAINT chk_notified_overdue CHECK (notified_overdue IN (0,1))
);
ALTER TABLE csrimp.issue ADD (notified_overdue NUMBER(1));
ALTER TABLE chain.product_metric_val ADD note VARCHAR2(4000);
ALTER TABLE chain.product_supplier_metric_val ADD note VARCHAR2(4000);
ALTER TABLE SURVEYS.QUESTION_OPTION_TAG DROP PRIMARY KEY DROP INDEX;
BEGIN
	security.user_pkg.LogonAdmin;
	DELETE FROM SURVEYS.QUESTION_OPTION_TAG;
END;
/
ALTER TABLE SURVEYS.QUESTION_OPTION_TAG ADD (
	QUESTION_ID				 	NUMBER(10, 0)	 NOT NULL,
	QUESTION_VERSION		 	NUMBER(10, 0) 	NOT NULL,
	QUESTION_DRAFT			 	NUMBER(1)	 	NOT NULL,
	CONSTRAINT PK_QUESTION_OPTION_TAG PRIMARY KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, TAG_ID),
	CONSTRAINT FK_QUESTION_OPTION_TAG_OPTION FOREIGN KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT) REFERENCES SURVEYS.QUESTION_OPTION (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
);

ALTER TABLE CSR.CUSTOMER_FLOW_CAPABILITY 
  ADD (IS_SYSTEM_MANAGED NUMBER(1) DEFAULT 0 NOT NULL);

ALTER TABLE CSR.CUSTOMER_FLOW_CAPABILITY
  ADD CONSTRAINT CK_CUST_FLOW_CAP_IS_SYS_MNGD CHECK (IS_SYSTEM_MANAGED IN (0, 1)) ENABLE;

ALTER TABLE CSRIMP.CUSTOMER_FLOW_CAPABILITY 
  ADD (IS_SYSTEM_MANAGED NUMBER(1) NOT NULL);

ALTER TABLE CSRIMP.CUSTOMER_FLOW_CAPABILITY
  ADD CONSTRAINT CK_CUST_FLOW_CAP_IS_SYS_MNGD CHECK (IS_SYSTEM_MANAGED IN (0, 1)) ENABLE;

grant select, insert, update on csr.score_type_audit_type to csrimp;
grant select, insert, update, delete on csrimp.score_type_audit_type to tool_user;
GRANT SELECT, REFERENCES ON csr.ind TO surveys;
GRANT SELECT, REFERENCES ON csr.customer TO surveys;
GRANT SELECT ON csr.tag_group_member TO surveys;
GRANT SELECT ON csr.tag TO surveys;
GRANT SELECT ON csr.tag_group TO surveys;
GRANT SELECT ON chain.debug_log TO surveys;
GRANT SELECT ON chain.filter TO surveys;
GRANT SELECT ON chain.filter_field TO surveys;
GRANT SELECT, INSERT ON chain.filter_value TO surveys;
GRANT SELECT ON chain.saved_filter TO surveys;
GRANT SELECT ON chain.compound_filter TO surveys;
GRANT SELECT ON chain.v$filter_field TO surveys;
GRANT SELECT, INSERT, DELETE ON chain.tt_filter_object_data TO surveys;
grant select on security.securable_object to surveys;
GRANT SELECT, REFERENCES ON aspen2.lang TO surveys;
GRANT SELECT ON chain.filter_value_id_seq TO surveys;
GRANT EXECUTE ON aspen2.request_queue_pkg TO surveys;
GRANT EXECUTE ON chain.filter_pkg TO surveys;
GRANT EXECUTE ON security.security_pkg TO surveys;
GRANT EXECUTE ON security.securableobject_pkg TO surveys;
GRANT EXECUTE ON security.class_pkg TO surveys;
GRANT EXECUTE ON chain.T_FILTERED_OBJECT_TABLE TO surveys;
GRANT EXECUTE ON chain.T_FILTERED_OBJECT_ROW TO surveys;
GRANT EXECUTE ON security.T_ORDERED_SID_ROW TO surveys;


ALTER TABLE SURVEYS.QUESTION ADD CONSTRAINT FK_QUESTION_IND
    FOREIGN KEY (APP_SID, MAPS_TO_IND_SID, MEASURE_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID, MEASURE_SID)
;
ALTER TABLE SURVEYS.QUESTION ADD CONSTRAINT FK_QUESTION_CUSTOMER
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;
ALTER TABLE SURVEYS.QUESTION_VERSION ADD CONSTRAINT FK_QV_CUSTOMER
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;
ALTER TABLE SURVEYS.QUESTION_VERSION_TR ADD CONSTRAINT FK_QUESTON_VERSN_TR_LANGUAGE
	FOREIGN KEY (LANGUAGE_CODE)
	REFERENCES ASPEN2.LANG(LANG)
;
ALTER TABLE SURVEYS.QUESTION_OPTION_TR ADD CONSTRAINT FK_QUESTON_OPTN_TR_LANGUAGE
	FOREIGN KEY (LANGUAGE_CODE)
	REFERENCES ASPEN2.LANG(LANG)
;
ALTER TABLE SURVEYS.SURVEY_VERSION_TR ADD CONSTRAINT FK_SURVEY_VERSION_TR_LANG
	FOREIGN KEY (LANGUAGE_CODE)
	REFERENCES ASPEN2.LANG(LANG)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD CONSTRAINT FK_SURVEY_SECTION_TR_LANG
	FOREIGN KEY (LANGUAGE_CODE)
	REFERENCES ASPEN2.LANG(LANG)
;


INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15780,11158,'Fugitive Gas - R-1270 Propene (Propylene)',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15781,11158,'Fugitive Gas - R-448A',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15782,11158,'Fugitive Gas - R-449A',1,0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15783,11158,'Fugitive Gas - R-728 Nitrogen',1,0);
/* TODO 
	change fs.label to fsn.label before commit
*/
CREATE OR REPLACE VIEW csr.v$permit_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.permit_score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
		 SELECT cp.app_sid, cp.region_sid, SUM(DECODE(cpc.condition_type_id, NULL, NULL, 1)) total_items, SUM(DECODE(LOWER(fsn.label), 'compliant', 1, 0)) compliant_items
		  FROM csr.compliance_permit cp
		  LEFT JOIN csr.compliance_permit_condition cpc ON cpc.compliance_permit_id = cp.compliance_permit_id
		  LEFT JOIN csr.compliance_item_region cir ON cpc.compliance_item_id = cir.compliance_item_id
		  LEFT JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
		 WHERE lower(fsn.label) != 'inactive'
		 GROUP BY cp.app_sid, cp.region_sid
		)
		ORDER BY region_sid
	) t
;
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.comments_display_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.match_every_category, qv.detailed_help_link, qv.action
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid
	  WHERE q.matrix_parent_id is null;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.comments_display_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.match_every_category, 
		qv.detailed_help_link, qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft;
CREATE OR REPLACE VIEW chain.v$all_purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid ct_role_user_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN v$company_user cu -- this will do for now, but it probably performs horribly
	    ON cu.company_sid = pc.company_sid
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = cu.user_sid
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.deleted = 0
	   AND sc.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL)
	 GROUP BY sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid;




DELETE FROM csr.module
 WHERE module_id = 53;
CREATE OR REPLACE PROCEDURE csr.TEMP_EnableCapability(
	in_capability  					IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
)
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;
    -- just create a sec obj of the right type in the right place
    BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				SYS_CONTEXT('SECURITY','APP'), 
				security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;
	
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
			v_capabilities_sid, 
			class_pkg.GetClassId('CSRCapability'),
			in_capability,
			v_capability_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			IF in_swallow_dup_exception = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
			END IF;
	END;
END;
/
DECLARE
	v_host					VARCHAR2(255);
	v_capability_sid		NUMBER;
BEGIN
	security.user_pkg.logonAdmin();
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.initiatives_options
	)
	LOOP
		SELECT host
		  INTO v_host
		  FROM csr.customer
		 WHERE app_sid = r.app_sid;
		
		security.user_pkg.logonAdmin(v_host);
		
		csr.TEMP_EnableCapability('Can import initiatives', 1);
		csr.TEMP_EnableCapability('Can purge initiatives', 1);
		csr.TEMP_EnableCapability('View initiatives audit log', 1);
		csr.TEMP_EnableCapability('Create users for approval', 1);
		
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
DROP PROCEDURE csr.TEMP_EnableCapability;
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (33, 'condition', 'Compliant');
INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1065, 'Non-Compliant Permit Conditions', 'Credit360.Portlets.Compliance.NonCompliantConditions', '/csr/site/portal/portlets/compliance/NonCompliantConditions.js');
UPDATE csr.flow_state set flow_state_nature_id = 33 where flow_state_id in (
	
SELECT fs.flow_state_id
  FROM csr.flow_state fs
  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND FS.lookup_key = 'COMPLIANT'
  JOIN csr.compliance_options co ON co.condition_flow_sid = f.flow_sid)
  
UPDATE csr.factor_type
   SET std_measure_id = 1
 WHERE name like '%(Mass)%'
   AND std_measure_id != 1;
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View user profiles', 0, 'User Management: Allows viewing of User Profile information');
BEGIN
	UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE'||unistr('\2122')||' Platform by UL EHS Sustainability</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;">our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
	UPDATE csr.alert_frame_body
	   SET html = REPLACE(html, 'PURE™', 'PURE'||unistr('\2122'))
	 WHERE html LIKE '%PURE™%';
END;
/
BEGIN
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Property.Plugins.IssuesPanel'
	 WHERE js_include = '/csr/site/property/properties/controls/IssuesPanel.js'
	   AND cs_class = 'Credit360.Plugins.PluginDto';
END;
/
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (21, 'Dataview - Xml Mapped Dsv',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableDsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (22, 'Dataview - Xml Mapped Excel',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableExcelOutputter');
DECLARE
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_doc_lib_daclid				security.securable_object.dacl_id%TYPE;
	v_admins						security.security_pkg.T_SID_ID;
	v_registered_users				security.security_pkg.T_SID_ID;
	v_doc_folder					security.security_pkg.T_SID_ID;
	v_ehs_managers					security.security_pkg.T_SID_ID;
	v_prop_managers					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (
		SELECT c.host, co.permit_doc_lib_sid
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_doc_lib_sid IS NOT NULL
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			v_app_sid := security.security_pkg.getApp;
			v_act_id := security.security_pkg.getAct;
			v_doc_folder := security.securableobject_pkg.GetSIDFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid,
				in_path						=> 'Documents'
			);
			
			v_doc_lib_daclid := security.acl_pkg.GetDACLIDForSID(v_doc_folder);
			
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act_id,
				in_acl_id 					=> v_doc_lib_daclid
			);
		
			-- Read/write for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			
			-- Add contents for EHS Managers
			v_ehs_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/EHS Managers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_ehs_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
			-- Add contents for Property Manager
			v_prop_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Property Manager'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_prop_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
					
			-- Read only for other users (property workflow permission check will also apply)
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		
			security.acl_pkg.PropogateACEs(
				in_act_id					=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid
			);
			
			security.user_pkg.logonadmin();
		EXCEPTION 
			WHEN OTHERS THEN 
				NULL;
		END;
	END LOOP;
END;
/
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1066, 'Site permit compliance levels', 'Credit360.Portlets.SitePermitComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SitePermitComplianceLevels.js');
DECLARE
	v_score_type_id 			NUMBER(10);
	v_ehs_managers_sid			NUMBER(10);
	v_portlet_ehs_mgr_tab_id	NUMBER(10);
	v_portlet_sid				NUMBER(10);
	v_tab_portlet_id			NUMBER(10);
	v_act_id					security.security_pkg.T_ACT_ID;
	v_groups_sid				NUMBER(10);
	PROCEDURE AddTabReturnTabId(
		in_app_sid		IN	security.security_pkg.T_SID_ID,
		in_tab_name		IN	csr.tab.name%TYPE,
		in_is_shared 	IN	csr.tab.is_shared%TYPE,
		in_is_hideable	IN	csr.tab.is_hideable%TYPE,
		in_layout		IN	csr.tab.layout%TYPE,
		in_portal_group	IN	csr.tab.portal_group%TYPE,
		out_tab_id		OUT	csr.tab.tab_id%TYPE
	)
	AS
		v_user_sid	security.security_pkg.T_SID_ID;
		v_max_pos 	csr.tab_user.pos%TYPE;
		v_tab_id	csr.tab.tab_id%TYPE;
	BEGIN
		v_user_sid := security.security_pkg.GetSID();
		SELECT NVL(MAX(pos),0)
			INTO v_max_pos
			FROM csr.v$tab_user
		 WHERE user_sid = v_user_sid
			 AND app_sid = in_app_sid;
		-- create a new tab
		INSERT INTO csr.TAB
			(tab_id, layout, name, app_sid, is_shared, is_hideable, portal_group)
		VALUES
			(csr.tab_id_seq.nextval, in_layout, in_tab_name, in_app_sid, in_is_shared, in_is_hideable, in_portal_group)
		RETURNING tab_id INTO v_tab_id;
		-- make user the owner
		INSERT INTO csr.TAB_USER
			(tab_id, user_sid, pos, is_owner)
		VALUES
			(v_tab_id, v_user_sid, v_max_pos+1, 1);
			
		out_tab_id := v_tab_id;
	END;
	
	FUNCTION GetOrCreateCustomerPortlet (
		in_portlet_type					IN  csr.portlet.type%TYPE
	) RETURN NUMBER
	AS
		v_portlet_id					csr.portlet.portlet_id%TYPE;
		v_portlet_sid					security.security_pkg.T_SID_ID;
		v_portlet_enabled				NUMBER;
		PROCEDURE EnablePortletForCustomer(
			in_portlet_id	IN csr.portlet.portlet_id%TYPE
		)
		AS
			v_customer_portlet_sid		security.security_pkg.T_SID_ID;
			v_type						csr.portlet.type%TYPE;
		BEGIN
			SELECT type
			  INTO v_type
			  FROM csr.portlet
			 WHERE portlet_id = in_portlet_id;
			
			BEGIN
				v_customer_portlet_sid := security.securableobject_pkg.GetSIDFromPath(
						SYS_CONTEXT('SECURITY','ACT'),
						SYS_CONTEXT('SECURITY','APP'),
						'Portlets/' || v_type);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
						security.securableobject_pkg.GetSIDFromPath(
							SYS_CONTEXT('SECURITY','ACT'),
							SYS_CONTEXT('SECURITY','APP'),
							'Portlets'),
						security.class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
			END;
		
			BEGIN
				INSERT INTO csr.customer_portlet
						(portlet_id, customer_portlet_sid, app_sid)
				VALUES
						(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
						NULL;
			END;
		END;
	BEGIN
		SELECT portlet_id
		  INTO v_portlet_id
		  FROM csr.portlet
		 WHERE type = in_portlet_type;
	
		SELECT COUNT(*)
		  INTO v_portlet_enabled
		  FROM csr.customer_portlet
		 WHERE portlet_id = v_portlet_id;
	
		IF v_portlet_enabled = 0 THEN
			EnablePortletForCustomer(v_portlet_id);
		END IF;
	
		SELECT customer_portlet_sid
		  INTO v_portlet_sid
		  FROM csr.customer_portlet
		 WHERE portlet_id = v_portlet_id;
		 
		RETURN v_portlet_sid;
	END;
	
	PROCEDURE AddPortletToTab(
		in_tab_id				IN	csr.tab_portlet.tab_id%TYPE,
		in_customer_portlet_sid	IN	csr.tab_portlet.customer_portlet_sid%TYPE,
		in_initial_state		IN	csr.tab_portlet.state%TYPE,
		out_tab_portlet_id		OUT	csr.tab_portlet.tab_portlet_id%TYPE
	)
	AS
		v_count					NUMBER(10);
	BEGIN
		-- move all portlets in first column position below
		UPDATE csr.TAB_PORTLET
			 SET pos = pos + 1
		 WHERE TAB_ID = in_tab_id
			 AND column_num = 0;
		
		INSERT INTO csr.TAB_PORTLET
			(customer_portlet_sid, tab_portlet_id, tab_id, column_num, pos, state)
		VALUES	
			(in_customer_portlet_sid, csr.tab_portlet_id_seq.nextval, in_tab_id, 0, 0, in_initial_state)
		RETURNING tab_portlet_id INTO out_tab_portlet_id;
	END;
BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			
			INSERT INTO csr.score_type (score_type_id, label, pos, hidden, allow_manual_set, lookup_key, applies_to_supplier, reportable_months)
			VALUES (csr.score_type_id_seq.nextval, 'Permit RAG', 0, 0, 0, 'PERMIT_RAG', 0, 0)
			RETURNING score_type_id INTO v_score_type_id;
			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Poor',	89, 16712965, 16712965,	16712965, v_score_type_id);
			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Low',	94, 16770048, 16770048,	16770048, v_score_type_id);
			INSERT INTO csr.score_threshold (score_threshold_id, description, max_value, text_colour, background_colour, bar_colour, score_type_id)
			VALUES (csr.score_threshold_id_seq.NEXTVAL, 'Good',	100, 3777539, 3777539,	3777539, v_score_type_id);
			UPDATE csr.compliance_options SET permit_score_type_id = v_score_type_id;
			
			v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
			v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups');
			v_ehs_managers_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'EHS Managers');
			
			SELECT MIN(tab_id)
			  INTO v_portlet_ehs_mgr_tab_id
			  FROM csr.tab
			 WHERE name = 'Permit compliance';
		
			 IF v_portlet_ehs_mgr_tab_id IS NULL THEN
		 		AddTabReturnTabId(
		 			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
		 			in_tab_name => 'Permit compliance',
		 			in_is_shared => 1,
		 			in_is_hideable => 1,
		 			in_layout => 6,
		 			in_portal_group => NULL,
		 			out_tab_id => v_portlet_ehs_mgr_tab_id
		 		);
		 	END IF;
			
			-- Add permissions on tabs.
			BEGIN
				INSERT INTO csr.tab_group(group_sid, tab_id)
				VALUES(v_ehs_managers_sid, v_portlet_ehs_mgr_tab_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		
			-- EHS Manager portlet tab contents.	
			v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.GeoMap');
			AddPortletToTab(
				in_tab_id => v_portlet_ehs_mgr_tab_id,
				in_customer_portlet_sid => v_portlet_sid,
				in_initial_state => '{"portletHeight":460,"pickerMode":0,"filterMode":0,"selectedRegionList":[],"includeInactiveRegions":false,"colourBy":"permitRag","portletTitle":"Site Permit RAG Status"}',
				out_tab_portlet_id => v_tab_portlet_id
			);
			
			v_portlet_sid := GetOrCreateCustomerPortlet('Credit360.Portlets.SitePermitComplianceLevels');
			
			AddPortletToTab(
				in_tab_id => v_portlet_ehs_mgr_tab_id,
				in_customer_portlet_sid => v_portlet_sid,
				in_initial_state => '',
				out_tab_portlet_id => v_tab_portlet_id
			);
				
			UPDATE csr.tab_portlet
			   SET column_num = 1, pos = 1
			 WHERE tab_portlet_id = v_tab_portlet_id;
			
			security.user_pkg.logonadmin();
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- Must have been enabled already
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('section', 'Section');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('radio', 'Radio button');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('checkboxgroup', 'Checkbox group');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('checkbox', 'Checkbox item');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('text', 'Text');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('pagebreak', 'Page break');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('matrix', 'Matrix');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('radiorow', 'Matrix radio button row');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('number', 'Number');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('slider', 'Slider');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('date', 'Date');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('files', 'Files');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('richtext', 'Text area');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('regionpicker', 'Region picker');
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('rtquestion', 'Rich text question');
END;
/
CREATE OR REPLACE PACKAGE surveys.survey_pkg AS END;
/
CREATE OR REPLACE PACKAGE surveys.question_library_pkg AS END;
/
CREATE OR REPLACE PACKAGE surveys.question_library_pkg AS END;
/
CREATE OR REPLACE PACKAGE surveys.question_library_report_pkg AS END;
/
BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE chain.customer_options
	   SET allow_duplicate_emails = 1;
END;
/
BEGIN
	INSERT INTO SURVEYS.QUESTION_TYPE(QUESTION_TYPE, LABEL) VALUES ('matrixdynamic', 'Matrix (dynamic rows)');
END;
/
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (34, 'condition', 'Action required');
UPDATE csr.flow_alert_class 
SET helper_pkg =  'csr.compliance_pkg'
WHERE flow_alert_class = 'condition';
UPDATE csr.issue 
   SET notified_overdue = 1
 WHERE due_dtm < SYSDATE;
INSERT INTO csr.schema_table (MODULE_NAME, OWNER, TABLE_NAME)
VALUES ('Permits', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');
INSERT INTO csr.schema_column (COLUMN_NAME, IS_MAP_SOURCE, MAP_NEW_ID_COL, MAP_OLD_ID_COL, MAP_TABLE, OWNER, TABLE_NAME)
VALUES('FLOW_ITEM_ID', 0, 'NEW_FLOW_ITEM_ID', 'OLD_FLOW_ITEM_ID', 'MAP_FLOW_ITEM', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');
INSERT INTO csr.schema_column (COLUMN_NAME, IS_MAP_SOURCE, MAP_NEW_ID_COL, MAP_OLD_ID_COL, MAP_TABLE, OWNER, TABLE_NAME)
VALUES('ISSUE_SCHEDULED_TASK_ID', 0, 'NEW_ISSUE_SCHEDULED_TASK_ID', 'OLD_ISSUE_SCHEDULED_TASK_ID', 'MAP_ISSUE_SCHEDULED_TASK', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (35, 'permit', 'Updated');
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit scheduled actions tab', '/csr/site/compliance/controls/PermitScheduledActionsTab.js', 'Credit360.Compliance.Controls.PermitScheduledActionsTab', 'Credit360.Compliance.Plugins.PermitScheduledActionsTab', 'Shows permit scheduled actions.');
UPDATE csr.issue_type 
   SET helper_pkg = 'csr.permit_pkg' 
 WHERE issue_type_id = 22;
 
INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1067, 'Active permit applications', 'Credit360.Portlets.Compliance.ActivePermitApplications', '/csr/site/portal/portlets/compliance/ActivePermitApplications.js');
INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1068, 'Applications summary', 'Credit360.Portlets.Compliance.PermitApplicationSummary', '/csr/site/portal/portlets/compliance/PermitApplicationSummary.js');
BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1001 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE */, 'campaign', 'Survey response', 0 /*Specific*/, 1 /*security_pkg.PERMISSION_READ*/);
	--move existing perms to flow_capabilitiees
	security.user_pkg.logonadmin;
	INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, group_sid,
		flow_involvement_type_id, permission_set)		 
	SELECT fsr.app_sid, csr.flow_state_rl_cap_id_seq.nextval, fsr.flow_state_id, 1001, fsr.role_sid, fsr.group_sid,
		NULL, DECODE(is_editable, 0, 1 /*security_pkg.PERMISSION_READ*/, 1 /*security_pkg.PERMISSION_READ*/ + 2 /*security_pkg.PERMISSION_WRITE*/)
	  FROM csr.flow_state_role fsr
	  JOIN csr.flow_state fs ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
	  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
	 WHERE f.flow_alert_class = 'campaign';
	--we don't need is_editable for campaigns anymore
	UPDATE csr.flow_state_role
	   SET is_editable = 0
	 WHERE flow_state_id IN (
		SELECT fs.flow_state_id
		  FROM csr.flow_state fs
		  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
	 	 WHERE f.flow_alert_class = 'campaign')
	   AND is_editable = 1;
	INSERT INTO csr.flow_inv_type_alert_class(app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT cfac.app_sid, 1001 /*FLOW_INV_TYPE_PURCHASER*/, cfac.flow_alert_class
	  FROM csr.customer_flow_alert_class cfac
	 WHERE cfac.flow_alert_class IN ('audit', 'campaign')
	   AND EXISTS (
			SELECT 1
			  FROM csr.flow_involvement_type fit
			 WHERE fit.app_sid = cfac.app_sid
			   AND fit.flow_involvement_type_id = 1001
	   )
	   AND NOT EXISTS(
			SELECT 1
			  FROM csr.flow_inv_type_alert_class fitac
			 WHERE fitac.app_sid = cfac.app_sid
			   AND fitac.flow_alert_class = cfac.flow_alert_class
			   AND fitac.flow_involvement_type_id = 1001
	   );
END;
/
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
		in_capability_type	=> 1,  												/* CT_COMPANY */
		in_capability		=> 'Product metric values as supplier',				/* PRODUCT_METRIC_VAL_AS_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 0
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  												/* CT_SUPPLIERS */
		in_capability		=> 'Product supplier metric values',				/* PRD_SUPP_METRIC_VAL */
		in_perm_type		=> 0,												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  												/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product supplier metric values of suppliers',	/* PRD_SUPP_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  												/* CT_COMPANY */
		in_capability		=> 'Product supplier metric values as supplier',	/* PRD_SUPP_METRIC_VAL_AS_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 0
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
DELETE FROM chain.company_type_capability WHERE capability_id IN (
	SELECT capability_id
	  FROM chain.capability
	 WHERE capability_name IN ('Supplier product metric values', 'Supplier product metric values of suppliers', 'Product metric values of suppliers')
);
DELETE FROM chain.capability WHERE capability_name = 'Supplier product metric values';
DELETE FROM chain.capability WHERE capability_name = 'Supplier product metric values of suppliers';
DELETE FROM chain.capability WHERE capability_name = 'Product metric values of suppliers';
DECLARE
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_doc_lib_daclid				security.securable_object.dacl_id%TYPE;
	v_doc_folder_daclid				security.securable_object.dacl_id%TYPE;
	v_admins						security.security_pkg.T_SID_ID;
	v_registered_users				security.security_pkg.T_SID_ID;
	v_doc_folder					security.security_pkg.T_SID_ID;
	v_ehs_managers					security.security_pkg.T_SID_ID;
	v_prop_managers					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (
		SELECT c.host, co.permit_doc_lib_sid
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_doc_lib_sid IS NOT NULL
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			v_app_sid := security.security_pkg.getApp;
			v_act_id := security.security_pkg.getAct;
			v_doc_folder := security.securableobject_pkg.GetSIDFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid,
				in_path						=> 'Documents'
			);
		
			security.securableobject_pkg.ClearFlag(
				in_act_id					=> v_act_id,
				in_sid_id					=> r.permit_doc_lib_sid,
				in_flag						=> security.security_pkg.SOFLAG_INHERIT_DACL
			);
		
			-- Clear ACL
			v_doc_lib_daclid := security.acl_pkg.GetDACLIDForSID(r.permit_doc_lib_sid);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act_id,
				in_acl_id 					=> v_doc_lib_daclid
			);
			
			v_doc_folder_daclid := security.acl_pkg.GetDACLIDForSID(v_doc_folder);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act_id,
				in_acl_id 					=> v_doc_folder_daclid
			);
		
			-- Read/write for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		
			-- Add contents for EHS Managers
			v_ehs_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/EHS Managers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_folder_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_ehs_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
		
			-- Add contents for Property Manager
			v_prop_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Property Manager'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_folder_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_prop_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
		
			-- Read only for other users (property workflow permission check will also apply)
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		
			security.acl_pkg.PropogateACEs(
				in_act_id					=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid
			);
			
			security.user_pkg.logonadmin();
		EXCEPTION 
			WHEN OTHERS THEN 
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	UPDATE csr.customer_flow_capability
	   SET is_system_managed = 1
	 WHERE flow_capability_id in (
		  SELECT csr_cfc.flow_capability_id
			FROM csr.customer_flow_capability csr_cfc
			JOIN chain.capability_flow_capability ch_cfc ON ch_cfc.flow_capability_id = csr_cfc.flow_capability_id
			JOIN chain.capability cap ON cap.capability_id = ch_cfc.capability_id
		   WHERE ( cap.capability_name IN ('Company', 'Suppliers'))
		   GROUP BY csr_cfc.flow_capability_id);
END;
/

GRANT EXECUTE ON surveys.survey_pkg TO security;
GRANT EXECUTE ON surveys.survey_pkg TO web_user;
GRANT EXECUTE ON surveys.question_library_pkg TO web_user;
GRANT EXECUTE ON surveys.question_library_report_pkg TO web_user;


@..\period_span_pattern_pkg
@..\automated_export_pkg
@..\csr_data_pkg
@..\compliance_pkg
@..\tag_pkg
@..\user_profile_pkg
@..\audit_pkg
@..\automated_import_pkg
@..\doc_folder_pkg
@..\permit_pkg
@..\quick_survey_pkg
@..\schema_pkg
--@..\surveys\survey_pkg
--@..\surveys\question_library_pkg
--@..\surveys\question_library_report_pkg
@..\chain\helper_pkg
@..\chain\company_user_pkg
@..\chain\filter_pkg
@..\flow_pkg
@..\issue_pkg
@..\csr_data_pkg 
@..\permit_pkg  
@..\campaign_pkg
@..\chain\chain_pkg
@..\chain\product_metric_pkg
@..\chain\company_product_pkg


@..\csr_app_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\enable_body
@..\period_span_pattern_body
@..\automated_export_body
@..\compliance_setup_body
@..\compliance_body
@..\tag_body
@..\user_profile_body
@..\audit_body
@..\chain\company_body
@..\automated_import_body
@..\dataview_body
@..\doc_folder_body
@..\supplier_body
@..\batch_job_body
@..\geo_map_body
@..\permit_body
@..\property_report_body
@..\schema_body
@..\csrimp\imp_body
@..\quick_survey_body
--@..\surveys\question_library_body
--@..\surveys\survey_body
--@..\surveys\question_library_report_body
@..\chain\company_user_body
@..\chain\helper_body
@..\meter_body
@..\meter_monitor_body
@..\..\..\aspen2\cms\db\filter_body
@..\audit_report_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\initiative_report_body
@..\meter_list_body
@..\non_compliance_report_body
@..\permit_report_body
@..\region_report_body
@..\flow_body
@..\issue_body
@..\enable_body 
@..\permit_body  
@..\compliance_body  
@..\csr_app_body 
@..\campaign_body
@..\chain\setup_body
@..\chain\product_metric_body
@..\chain\company_product_body
@..\chain\type_capability_body

@update_tail
