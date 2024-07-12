define version=3296
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
CREATE TABLE CSR.SYS_TRANSLATIONS_AUDIT_DATA(
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)        NOT NULL,
	AUDIT_DATE						DATE DEFAULT      SYSDATE NOT NULL,
	APP_SID							NUMBER(10,0)      DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	IS_DELETE						NUMBER(1,0)       NOT NULL,
	ORIGINAL						VARCHAR2(4000),
	TRANSLATION						VARCHAR2(4000),
	OLD_TRANSLATION					VARCHAR2(4000),
	CONSTRAINT PK_SYS_TRANS_AUDIT_DATA PRIMARY KEY (SYS_TRANSLATIONS_AUDIT_LOG_ID)
)
;
CREATE TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_DATA(
	CSRIMP_SESSION_ID				NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)			NOT NULL,
	AUDIT_DATE						DATE				NOT NULL,
	APP_SID							NUMBER(10,0)		NOT NULL,
	IS_DELETE						NUMBER(1,0)			NOT NULL,
	ORIGINAL						VARCHAR2(4000),
	TRANSLATION						VARCHAR2(4000),
	OLD_TRANSLATION					VARCHAR2(4000),
	CONSTRAINT PK_SYS_TRANS_AUDIT_DATA PRIMARY KEY (CSRIMP_SESSION_ID, SYS_TRANSLATIONS_AUDIT_LOG_ID),
	CONSTRAINT FK_SYS_TRANS_AUDIT_DATA FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE TABLE cms.form_response_import_options(
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	form_id				VARCHAR2(255) NOT NULL,
	helper_sp			VARCHAR2(400) NOT NULL,
	CONSTRAINT PK_FORM_RESPONSE_IMPORT_OPT PRIMARY KEY (app_sid, form_id, helper_sp),
	CONSTRAINT UK_FORM_RESP_APP UNIQUE (app_sid, form_id)
);
CREATE TABLE cms.form_response(
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	form_id				VARCHAR2(255) NOT NULL,
	form_version		NUMBER NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	user_sid			NUMBER(10), --NOT NULL,			-- TODO - make this NOT NULL when API is sending user ID!
	retrieved_dtm		DATE DEFAULT SYSDATE NOT NULL,
	response_json		CLOB NOT NULL,
	processed_dtm		DATE,
	failure_dtm			DATE,
	failure_msg			CLOB,
	CONSTRAINT PK_FORM_RESPONSE PRIMARY KEY (app_sid, form_id, form_version, response_id),
	CONSTRAINT UK_FORM_RESP_IMP_ID UNIQUE (app_sid, import_id),
	CONSTRAINT FK_FORM_RESP_FORM FOREIGN KEY (app_sid, form_id) REFERENCES cms.form_response_import_options(app_sid, form_id)
);
CREATE TABLE cms.form_response_answer(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR(255) NOT NULL,
	answer_type			VARCHAR(100) NOT NULL,
	answer_text			CLOB,
	answer_num			NUMBER,
	answer_dtm			DATE,
	CONSTRAINT PK_FORM_RESP_ANS PRIMARY KEY (app_sid, import_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_ANS_IMP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id),
	CONSTRAINT CHK_FORM_RESP_ANS_TYPE CHECK (answer_type IN ('null', 'string', 'number', 'date', 'stringlist'))				-- string-list = multiple (lookup in form_response_answer_option table). null = unanswered question but could have file attachments.
);
CREATE TABLE cms.form_response_answer_option(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	option_id			NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	option_value		VARCHAR2(2048) NOT NULL,
	CONSTRAINT PK_FORM_RESP_ANS_OPT PRIMARY KEY (app_sid, import_id, response_id, option_id),
	CONSTRAINT FK_FORM_RESP_ANS_OPT_IMP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id),
	CONSTRAINT FK_FORM_RESP_ANS_OPT_RESP_ANS FOREIGN KEY (app_sid, import_id, response_id, data_key) REFERENCES cms.form_response_answer(app_sid, import_id, response_id, data_key)
);
CREATE INDEX cms.ix_form_response_opt_imp_id ON cms.form_response_answer_option (app_sid, import_id, response_id, data_key);
CREATE TABLE cms.form_response_answer_file(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	file_id				NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	file_data			BLOB NOT NULL,
	CONSTRAINT PK_FORM_RESP_ANS_FILE PRIMARY KEY (app_sid, file_id),
	CONSTRAINT UK_FORM_RESP_ANS_FILE_RESP UNIQUE (app_sid, file_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_ANSWER FOREIGN KEY (app_sid, import_id, response_id, data_key) REFERENCES cms.form_response_answer(app_sid, import_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id)
);
CREATE INDEX cms.ix_form_response_file_imp_id ON cms.form_response_answer_file (app_sid, import_id);
CREATE INDEX cms.ix_form_response_file_id_resp_dk ON cms.form_response_answer_file (app_sid, import_id, response_id, data_key);
CREATE SEQUENCE CMS.FORM_RESP_IMPORT_ID_SEQ;
CREATE SEQUENCE CMS.FORM_RESP_ANS_OPT_ID_SEQ;
CREATE SEQUENCE CMS.FORM_RESP_ANS_FILE_ID_SEQ;


ALTER TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_LOG MODIFY AUDIT_DATE DEFAULT NULL;
DECLARE
	v_count		NUMBER;
BEGIN
	FOR r IN (
		SELECT *
		  FROM all_constraints
		 WHERE owner = 'CSRIMP'
		   AND constraint_name IN ('FK_NON_COMP_TYP_CAPAB','FK_CAL_CI')
		)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE owner = 'CSRIMP'
	   AND constraint_name = 'FK_CAL_IS';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.compliance_audit_log ADD CONSTRAINT FK_CAL_IS FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)';
	END IF;
END;
/
CREATE INDEX csr.ix_compliance_req_reg_req ON csr.compliance_req_reg (app_sid, requirement_id);
CREATE INDEX csr.ix_ci_desc_ci ON csr.compliance_item_description (app_sid, compliance_item_id);
DECLARE
	v_count			NUMBER;
BEGIN
	FOR i IN (
		SELECT *
		  FROM all_indexes
		 WHERE UPPER(owner) = 'CSR'
		   AND UPPER(index_name) IN ('IDX_VAL_CHANGE_USER_DATE', 'IDX_VAL_CHANGE_SOURCE_TYPE')
	) LOOP
		EXECUTE IMMEDIATE 'DROP INDEX csr.'||i.index_name;
	END LOOP;
	FOR f IN (
		SELECT *
		  FROM all_constraints
		 WHERE UPPER(owner) = 'CSR'
		   AND UPPER(constraint_name) IN ('REFSOURCE_TYPE206','REFCSR_USER1045')
		   AND constraint_type = 'R'
		   AND status = 'ENABLED'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.'||f.table_name||' DISABLE CONSTRAINT '||f.constraint_name;
	END LOOP;
END;
/


grant select,insert, update on csr.sys_translations_audit_data to csrimp;
grant select, insert, update, delete on csrimp.sys_translations_audit_data to tool_user;














@..\schema_pkg
@ ..\unit_test_pkg
@ ..\issue_pkg
@..\csr_user_pkg
@..\..\..\aspen2\cms\db\form_response_import_pkg
@..\region_tree_pkg


@..\csrimp\imp_body
@..\csr_app_body
@..\schema_body
@..\customer_body
@..\compliance_register_report_body
@ ..\issue_body
@ ..\issue_report_body
@..\audit_body
@..\csr_user_body
@..\..\..\aspen2\cms\db\form_response_import_body
@..\sheet_body
@..\region_tree_body
@..\region_body
@..\enable_body
@..\property_body
@..\quick_survey_body
@..\compliance_body
@ ..\audit_body
@..\issue_report_body



@update_tail
