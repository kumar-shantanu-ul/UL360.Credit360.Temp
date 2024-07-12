define version=2972
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

DECLARE
	PROCEDURE DropSequence(
		in_sequence_name	VARCHAR2
	)
	AS
	BEGIN
		EXECUTE IMMEDIATE 'DROP SEQUENCE CSR.'||in_sequence_name;
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -2289 THEN
				-- -2289 == sequence does not exist
				RAISE;
			END IF;
	END;
BEGIN
	DropSequence('AUT_EXP_INS_FILE_ID_SEQ');
	DropSequence('AUT_EXPORT_IND_CONF_ID_SEQ');
	DropSequence('CHANGE_STEP_ID_SEQ');
	DropSequence('ERROR_LOG_ID_SEQ');
	DropSequence('FACTOR_SET_ID_SEQ');
	DropSequence('FUND_MGR_CONTACT_ID_SEQ');
	DropSequence('IND_ASSERTION_ID_SEQ');
	DropSequence('ISSUE_URL_ID_SEQ');
	DropSequence('MGMT_COMPANY_ID');
	DropSequence('PENDING_VAL_COMMENT_ID_SEQ');
	DropSequence('REASON_ID');
	DropSequence('SCHEDULE_ID_SEQ');
	DropSequence('STD_MEASURE_ID_SEQ');
	DropSequence('TARGET_ID_SEQ');
	DropSequence('UTILITY_INVOICE_COMMENT_ID_SEQ');
END;
/

CREATE TABLE csr.tpl_report_reg_data_type (
	tpl_report_reg_data_type_id 	NUMBER(10) NOT NULL,
    description						VARCHAR2(255) NOT NULL,
    pos								NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_reg_data_type PRIMARY KEY (tpl_report_reg_data_type_id)
);
CREATE SEQUENCE csr.tpl_report_tag_reg_data_id_seq;
CREATE TABLE csr.tpl_report_tag_reg_data (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	tpl_report_tag_reg_data_id     	NUMBER(10) NOT NULL,
    tpl_report_reg_data_type_id		NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_tag_reg_data PRIMARY KEY (app_sid, tpl_report_tag_reg_data_id),
    CONSTRAINT fk_tpl_report_reg_data_type FOREIGN KEY (tpl_report_reg_data_type_id) REFERENCES csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id)
);
CREATE INDEX csr.ix_tpl_report_ta_tpl_report_re ON csr.tpl_report_tag_reg_data (tpl_report_reg_data_type_id);
CREATE TABLE csrimp.tpl_report_tag_reg_data (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tpl_report_tag_reg_data_id     	NUMBER(10) NOT NULL,
    tpl_report_reg_data_type_id		NUMBER(10) NOT NULL,
    CONSTRAINT pk_tpl_report_tag_reg_data PRIMARY KEY (csrimp_session_id, tpl_report_tag_reg_data_id),
    CONSTRAINT fk_tpl_report_tag_reg_data_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.map_tpl_report_tag_reg_data (
	csrimp_session_id					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_reg_data PRIMARY KEY (csrimp_session_id, old_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_reg_data UNIQUE (csrimp_session_id, new_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT fk_map_tpl_rep_tag_reg_data_is FOREIGN KEY
		(csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id)
		ON DELETE CASCADE
);
CREATE SEQUENCE CSR.FACTOR_SET_ID_SEQ START WITH 1000;
CREATE SEQUENCE csr.compliance_item_seq CACHE 5;
CREATE TABLE csr.compliance_item (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	title							VARCHAR2(255) NOT NULL,
	summary							VARCHAR2(1024) NULL,
	details							CLOB NULL, -- xhtml
	source							NUMBER(3,0) DEFAULT 0 NOT NULL, -- 0 = Manual, 1 = ENHESA
	country							VARCHAR2(2) NULL,
	region							VARCHAR2(2) NULL,
	country_group					VARCHAR2(3) NULL,
	reference_code					VARCHAR2(255) NULL, 
	user_comment					VARCHAR2(1024) NULL,
	citation						VARCHAR2(1024) NULL,
	external_link					VARCHAR2(1024) NULL,
	created_dtm						DATE DEFAULT SYSDATE NOT NULL,
	updated_dtm						DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT pk_compliance_item	PRIMARY KEY (app_sid, compliance_item_id),
	CONSTRAINT ck_compliance_item_source CHECK (source in (0, 1))
);
CREATE INDEX csr.ix_compliance_item_pcr ON csr.compliance_item (country, region);
CREATE INDEX csr.ix_compliance_item_cg ON csr.compliance_item (country_group);
CREATE UNIQUE INDEX uk_compliance_item_ref ON csr.compliance_item (
	nvl2(reference_code, app_sid, null), 
	reference_code
);
CREATE TABLE csr.compliance_requirement (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_requirement PRIMARY KEY (app_sid, compliance_item_id)
);
CREATE TABLE csr.compliance_regulation (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	adoption_dtm					DATE NULL,
	CONSTRAINT pk_compliance_regulation PRIMARY KEY (app_sid, compliance_item_id)
);
CREATE TABLE csr.compliance_item_tag (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	tag_id							NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_item_tag PRIMARY KEY (app_sid, compliance_item_id, tag_id)
);
CREATE INDEX csr.ix_compliance_item_tag_id ON csr.compliance_item_tag (app_sid, tag_id);
CREATE TABLE csr.compliance_item_region (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	flow_item_id					NUMBER(10,0) NULL,
	CONSTRAINT pk_compliance_item_region PRIMARY KEY (app_sid, compliance_item_id, region_sid)
);
CREATE INDEX csr.ix_compliance_item_region ON csr.compliance_item_region (app_sid, region_sid);
CREATE TABLE csr.compliance_req_reg (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	requirement_id					NUMBER(10,0) NOT NULL,
	regulation_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_req_reg PRIMARY KEY (app_sid, requirement_id, regulation_id)
);
CREATE INDEX csr.ix_compliance_req_reg ON csr.compliance_req_reg (app_sid, regulation_id);
CREATE TABLE csr.country_group (
	country_group_id				VARCHAR2(3) NOT NULL,
	group_name						VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_country_group PRIMARY KEY (country_group_id)
);
CREATE TABLE csr.country_group_country (
	country_group_id				VARCHAR2(3) NOT NULL,
	country_id						VARCHAR2(2) NOT NULL,
	CONSTRAINT pk_country_group_country PRIMARY KEY (country_group_id, country_id)
);
CREATE INDEX csr.ix_country_group_country ON csr.country_group_country (country_id);
CREATE TABLE csrimp.compliance_item (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	title							VARCHAR2(255) NOT NULL,
	summary							VARCHAR2(1024) NULL,
	details							CLOB NULL, -- xhtml
	source							NUMBER(3,0) NOT NULL, -- 0 = Manual, 1 = ENHESA
	country							VARCHAR2(2) NULL,
	region							VARCHAR2(2) NULL,
	country_group					VARCHAR2(3) NULL,
	reference_code					VARCHAR2(255) NULL, 
	user_comment					VARCHAR2(1024) NULL,
	citation						VARCHAR2(1024) NULL,
	external_link					VARCHAR2(1024) NULL,
	created_dtm						DATE NOT NULL,
	updated_dtm						DATE NOT NULL,
	CONSTRAINT pk_compliance_item	PRIMARY KEY (csrimp_session_id, compliance_item_id),
	CONSTRAINT ck_compliance_item_source CHECK (source in (0, 1)),
	CONSTRAINT fk_compliance_item_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_requirement (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_requirement PRIMARY KEY (csrimp_session_id, compliance_item_id),
	CONSTRAINT fk_compliance_requirement_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_regulation (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	adoption_dtm					DATE NULL,
	CONSTRAINT pk_compliance_regulation PRIMARY KEY (csrimp_session_id, compliance_item_id),
	CONSTRAINT fk_compliance_regulation_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_item_tag (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	tag_id							NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_item_tag PRIMARY KEY (csrimp_session_id, compliance_item_id, tag_id),
	CONSTRAINT fk_compliance_item_tag_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_item_region (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	flow_item_id					NUMBER(10,0) NULL,
	CONSTRAINT pk_compliance_item_region PRIMARY KEY (csrimp_session_id, compliance_item_id, region_sid),
	CONSTRAINT fk_compliance_item_region_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_req_reg (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	requirement_id					NUMBER(10,0) NOT NULL,
	regulation_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_req_reg PRIMARY KEY (csrimp_session_id, requirement_id, regulation_id),
	CONSTRAINT fk_compliance_req_reg_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);
CREATE TABLE csrimp.map_compliance_item (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_id			NUMBER(10) NOT NULL,
	new_compliance_item_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item PRIMARY KEY (csrimp_session_id, old_compliance_item_id),
	CONSTRAINT uk_map_compliance_item UNIQUE (csrimp_session_id, new_compliance_item_id),
	CONSTRAINT fk_map_compliance_item FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'CMS'
		   AND table_name IN ('DOC_TEMPLATE_FILE', 'DOC_TEMPLATE_VERSION', 'DOC_TEMPLATE')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CMS.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/
CREATE TABLE CMS.DOC_TEMPLATE (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10) NOT NULL,
	NAME					VARCHAR2(128) NOT NULL,
	LOOKUP_KEY				VARCHAR2(128) NOT NULL,
	LANG					VARCHAR2(10),
	CONSTRAINT PK_DOC_TEMPLATE PRIMARY KEY (APP_SID, DOC_TEMPLATE_ID),
	CONSTRAINT UK_DOC_TEMPLATE UNIQUE (APP_SID, LOOKUP_KEY, LANG)
);
CREATE TABLE CMS.DOC_TEMPLATE_FILE (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10) NOT NULL,
	FILE_NAME				VARCHAR2(256),
	FILE_MIME				VARCHAR2(256),
	FILE_DATA				BLOB,
	UPLOADED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_DOC_TEMPLATE_FILE PRIMARY KEY (APP_SID, DOC_TEMPLATE_FILE_ID)
);
CREATE TABLE CMS.DOC_TEMPLATE_VERSION (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10) NOT NULL,
	VERSION					NUMBER(10) NOT NULL,
	COMMENTS				CLOB NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10) NOT NULL,
	LOG_DTM					DATE DEFAULT SYSDATE NOT NULL,
	USER_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	PUBLISHED_DTM			DATE,
	ACTIVE					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_VERSION PRIMARY KEY (APP_SID, DOC_TEMPLATE_ID, VERSION)
);
BEGIN
	FOR r IN (
		SELECT sequence_name
		  FROM all_sequences
		 WHERE sequence_owner = 'CMS'
		   AND sequence_name IN ('DOC_TEMPLATE_ID_SEQ', 'DOC_TEMPLATE_FILE_ID_SEQ')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP SEQUENCE CMS.' || r.sequence_name;
	END LOOP;
END;
/
CREATE SEQUENCE CMS.DOC_TEMPLATE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;
CREATE SEQUENCE CMS.DOC_TEMPLATE_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'CSRIMP'
		   AND table_name IN ('MAP_DOC_TEMPLATE', 'MAP_DOC_TEMPLATE_FILE', 'CMS_DOC_TEMPLATE_VERSION', 'CMS_DOC_TEMPLATE_FILE', 'CMS_DOC_TEMPLATE')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CSRIMP.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/
CREATE TABLE csrimp.map_cms_doc_template (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_id		NUMBER(10)	NOT NULL,
	new_doc_template_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template PRIMARY KEY (csrimp_session_id, old_doc_template_id) USING INDEX,
	CONSTRAINT uk_map_doc_template UNIQUE (csrimp_session_id, new_doc_template_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_cms_doc_template_file (
	csrimp_session_id			NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_file_id	NUMBER(10)	NOT NULL,
	new_doc_template_file_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template_file PRIMARY KEY (csrimp_session_id, old_doc_template_file_id) USING INDEX,
	CONSTRAINT uk_map_doc_template_file UNIQUE (csrimp_session_id, new_doc_template_file_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_file_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE (
	CSRIMP_SESSION_ID		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10)		NOT NULL,
	NAME					VARCHAR2(128)	NOT NULL,
	LOOKUP_KEY				VARCHAR2(128)	NOT NULL,
	LANG					VARCHAR2(10),
	CONSTRAINT PK_CMS_DOC_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_ID),
	CONSTRAINT UK_CMS_DOC_TEMPLATE UNIQUE (CSRIMP_SESSION_ID, LOOKUP_KEY, LANG),
	CONSTRAINT FK_CMS_DOC_TEMPLATE FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE_FILE (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10)	NOT NULL,
	FILE_NAME				VARCHAR2(256),
	FILE_MIME				VARCHAR2(256),
	FILE_DATA				BLOB,
	UPLOADED_DTM			DATE		NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_FILE PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_FILE_ID),
	CONSTRAINT FK_CMS_DOC_TEMPLATE_FILE FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE_VERSION (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10)	NOT NULL,
	VERSION					NUMBER(10)	NOT NULL,
	COMMENTS				CLOB		NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10)	NOT NULL,
	LOG_DTM					DATE		NOT NULL,
	USER_SID				NUMBER(10)	NOT NULL,
	PUBLISHED_DTM			DATE,
	ACTIVE					NUMBER(1)	NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_VERS PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_ID, VERSION),
	CONSTRAINT FK_CMS_DOC_TEMPLATE_VERSION FOREIGN KEY 
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


ALTER TABLE CSRIMP.EMISSION_FACTOR_PROFILE DROP COLUMN ACTIVE;
ALTER TABLE CSR.EMISSION_FACTOR_PROFILE_FACTOR ADD CONSTRAINT FK_EMISSION_FACTOR_PROFILE 
    FOREIGN KEY (APP_SID, PROFILE_ID)
    REFERENCES CSR.EMISSION_FACTOR_PROFILE(APP_SID, PROFILE_ID) ON DELETE CASCADE
;
ALTER TABLE CSR.EMISSION_FACTOR_PROFILE DROP COLUMN ACTIVE;
ALTER TABLE csr.issue_type ADD(
	enable_manual_comp_date		NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csr.issue ADD(
	manual_completion_dtm		DATE,
	manual_comp_dtm_set_dtm		DATE
);
ALTER TABLE csr.issue_action_log ADD(
	new_manual_comp_dtm_set_dtm	DATE,
	new_manual_comp_dtm			DATE
);
ALTER TABLE csr.temp_issue_search ADD(
	manual_completion_dtm		DATE
);
ALTER TABLE csrimp.issue_type ADD(
	enable_manual_comp_date		NUMBER(1) NOT NULL
);
ALTER TABLE csrimp.issue ADD(
	manual_completion_dtm		DATE,
	manual_comp_dtm_set_dtm		DATE
);
ALTER TABLE csrimp.issue_action_log ADD(
	new_manual_comp_dtm_set_dtm	DATE,
	new_manual_comp_dtm			DATE
);
ALTER TABLE csr.tpl_report_tag ADD (
	tpl_report_tag_reg_data_id		NUMBER(10),
    CONSTRAINT fk_tpl_report_tag_reg_data
    	FOREIGN KEY (app_sid, tpl_report_tag_reg_data_id)
    	REFERENCES csr.tpl_report_tag_reg_data(app_sid, tpl_report_tag_reg_data_id) DEFERRABLE INITIALLY DEFERRED
);
CREATE INDEX csr.ix_tpl_report_ta_tpl_report_rg ON csr.tpl_report_tag (app_sid, tpl_report_tag_reg_data_id);
ALTER TABLE csrimp.tpl_report_tag ADD (
	tpl_report_tag_reg_data_id		NUMBER(10)
);
ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csr.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
);
ALTER TABLE csrimp.tpl_report_tag ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
    (tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
    OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
    OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
);
DROP SEQUENCE csr.custom_factor_set_id_seq;
ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY +200000000;
SELECT csr.std_factor_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY 1;
ALTER TABLE csr.compliance_options ADD (
	requirement_flow_sid		NUMBER(10,0) NULL,
	regulation_flow_sid			NUMBER(10,0) NULL
);
ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_req_flow 
	FOREIGN KEY (app_sid, requirement_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);
ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_reg_flow 
	FOREIGN KEY (app_sid, regulation_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);
ALTER TABLE csr.compliance_item_tag ADD CONSTRAINT fk_cit_ci 
	FOREIGN KEY (app_sid, compliance_item_id) 
	REFERENCES csr.compliance_item (app_sid, compliance_item_id);
ALTER TABLE csr.compliance_item_tag ADD CONSTRAINT fk_cit_t 
	FOREIGN KEY (app_sid, tag_id) 
	REFERENCES csr.tag (app_sid, tag_id);
ALTER TABLE csr.compliance_requirement ADD CONSTRAINT fk_cr_ci
	FOREIGN KEY (app_sid, compliance_item_id)
	REFERENCES csr.compliance_item (app_sid, compliance_item_id);
ALTER TABLE csr.compliance_regulation ADD CONSTRAINT fk_cr_cr
	FOREIGN KEY (app_sid, compliance_item_id)
	REFERENCES csr.compliance_item (app_sid, compliance_item_id);
ALTER TABLE csr.compliance_item_region ADD CONSTRAINT fk_cir_r
	FOREIGN KEY (app_sid, region_sid) 
	REFERENCES csr.region (app_sid, region_sid);
ALTER TABLE csr.compliance_req_reg ADD CONSTRAINT fk_crr_req
	FOREIGN KEY (app_sid, requirement_id)
	REFERENCES csr.compliance_requirement (app_sid, compliance_item_id);
ALTER TABLE csr.compliance_req_reg ADD CONSTRAINT fk_crr_reg
	FOREIGN KEY (app_sid, regulation_id)
	REFERENCES csr.compliance_regulation (app_sid, compliance_item_id);
ALTER TABLE csr.compliance_item ADD CONSTRAINT fk_ci_pcr
	FOREIGN KEY (country, region)
	REFERENCES postcode.region (country, region);
ALTER TABLE csr.compliance_item ADD CONSTRAINT fk_ci_pcc
	FOREIGN KEY (country)
	REFERENCES postcode.country (country);
ALTER TABLE csr.compliance_item ADD CONSTRAINT fk_ci_sn
	FOREIGN KEY (country_group)
	REFERENCES csr.country_group (country_group_id);
ALTER TABLE csr.tag_group ADD(
	applies_to_compliances	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CHECK (applies_to_compliances IN(0,1))
);
ALTER TABLE csr.country_group_country ADD CONSTRAINT fk_cgc_pc
	FOREIGN KEY (country_id)
	REFERENCES postcode.country (country);
ALTER TABLE csrimp.tag_group ADD (
	applies_to_compliances	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CHECK (applies_to_compliances IN(0,1))
);
GRANT CREATE TABLE TO csr;
/* COMPLIANCE ITEM TITLE INDEX */
create index csr.ix_ci_title_search on csr.compliance_item(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
/* COMPLIANCE ITEM SUMMARY INDEX */
create index csr.ix_ci_summary_search on csr.compliance_item(summary) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
/* COMPLIANCE ITEM DETAILS INDEX */
create index csr.ix_ci_details_search on csr.compliance_item(details) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
/* COMPLIANCE ITEM REFERENCE CODE INDEX */
create index csr.ix_ci_ref_code_search on csr.compliance_item(reference_code) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
/* COMPLIANCE ITEM USER COMMENT INDEX */
create index csr.ix_ci_usr_comment_search on csr.compliance_item(user_comment) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
/* COMPLIANCE ITEM CITATION INDEX */
create index csr.ix_ci_citation_search on csr.compliance_item(citation) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
REVOKE CREATE TABLE FROM csr;
DECLARE
	job BINARY_INTEGER;
BEGIN
	-- now and every minute afterwards
	-- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
		job_name			=> 'csr.compliance_item_text',
		job_type			=> 'PLSQL_BLOCK',
		job_action			=> 'ctx_ddl.sync_index(''ix_ci_title_search'');
								ctx_ddl.sync_index(''ix_ci_summary_search'');
								ctx_ddl.sync_index(''ix_ci_details_search'');
								ctx_ddl.sync_index(''ix_ci_ref_code_search'');
								ctx_ddl.sync_index(''ix_ci_usr_comment_search'');
								ctx_ddl.sync_index(''ix_ci_citation_search'');',
		job_class			=> 'low_priority_job',
		start_date			=> to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval		=> 'FREQ=MINUTELY',
		enabled				=> TRUE,
		auto_drop			=> FALSE,
		comments			=> 'Synchronise compliance item text indexes');
		COMMIT;
END;
/
DECLARE
	job BINARY_INTEGER;
BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name				=> 'csr.optimize_all_indexes',
		attribute			=> 'job_action',
		value				=> 'ctx_ddl.optimize_index(''ix_doc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_doc_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_sh_val_note_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_help_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_response_file_srch'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_ans_ans_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_log_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_notes_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_detail_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_rt_cse_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_summary_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_details_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_ref_code_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_usr_comment_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_citation_search'', ctx_ddl.OPTLEVEL_FULL);'
	);
	COMMIT;
END;
/
CREATE OR REPLACE PACKAGE csr.comp_requirement_report_pkg AS
END;
/
CREATE OR REPLACE PACKAGE csr.comp_regulation_report_pkg AS
END;
/
ALTER TABLE CHAIN.BSCI_SUPPLIER MODIFY POSTCODE NULL;
ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER MODIFY POSTCODE NULL;
ALTER TABLE chain.dedupe_processed_record ADD created_company_sid NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record ADD created_company_sid NUMBER(10, 0);
ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT fk_dedupe_proc_record_company
	FOREIGN KEY (app_sid, created_company_sid)
	REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.tt_dedupe_processed_row ADD created_company_sid NUMBER(10, 0);
ALTER TABLE chain.tt_dedupe_processed_row ADD created_company_name VARCHAR(512);
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_COMPANY_ROW AS 
	OBJECT ( 
		NAME				VARCHAR2(255),
		PARENT_COMPANY_NAME	VARCHAR2(255),
		COMPANY_TYPE		VARCHAR2(255),
		CREATED_DTM			DATE,
		ACTIVATED_DTM		DATE,
		ACTIVE				NUMBER(1),
		ADDRESS				VARCHAR2(512),
		STATE				VARCHAR2(255),
		POSTCODE			VARCHAR2(32),
		COUNTRY_CODE		VARCHAR2(255),
		PHONE				VARCHAR2(255),
		FAX					VARCHAR2(255),
		WEBSITE				VARCHAR2(255),
		EMAIL				VARCHAR2(255),
		DELETED				NUMBER(1),
		SECTOR				VARCHAR2(255),
		CITY				VARCHAR2(255),
		DEACTIVATED_DTM		DATE,
		CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
		RETURN self AS RESULT
	);
/
CREATE OR REPLACE TYPE BODY CHAIN.T_DEDUPE_COMPANY_ROW AS
  CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
	RETURN SELF AS RESULT
	AS
	BEGIN
		RETURN;
	END;
END;
/
ALTER TABLE aspen2.application ADD (
	monitor_with_new_relic NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.aspen2_application ADD (
	monitor_with_new_relic NUMBER(1)
);
UPDATE csrimp.aspen2_application
   SET monitor_with_new_relic = 0;
ALTER TABLE csrimp.aspen2_application
	MODIFY monitor_with_new_relic NOT NULL;
GRANT SELECT, REFERENCES ON ASPEN2.TRANSLATION_SET TO CMS WITH GRANT OPTION;
ALTER TABLE	CMS.DOC_TEMPLATE ADD CONSTRAINT FK_DOC_TEMPLATE_LANG
	FOREIGN KEY (APP_SID, LANG) REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG);
ALTER TABLE	CMS.DOC_TEMPLATE_VERSION ADD CONSTRAINT FK_DOC_TEMPLATE_VERSION_FILE
	FOREIGN KEY (APP_SID, DOC_TEMPLATE_FILE_ID) REFERENCES CMS.DOC_TEMPLATE_FILE (APP_SID, DOC_TEMPLATE_FILE_ID);
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'USER_TABLE'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.USER_TABLE DROP COLUMN REMOVE_ROLES_ON_DEACTIVATION';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column not existing.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'REMOVE_ROLES_ON_DEACTIVATION';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CSR_USER ADD REMOVE_ROLES_ON_DEACTIVATION NUMBER(1,0)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'USER_REF';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CSR_USER ADD USER_REF VARCHAR2(255)';
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CSR.UK_USER_REF ON CSR.CSR_USER(APP_SID,LOWER(NVL(USER_REF, ''CR360_'' || CSR_USER_SID)))';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/
DECLARE
	v_col_check NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'CSR_USER'
	   AND column_name = 'USER_REF';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CSR_USER ADD USER_REF VARCHAR2(255)';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip, column already created.');
	END IF;
END;
/


GRANT SELECT ON csr.tpl_report_tag_reg_data_id_seq TO csrimp;
GRANT INSERT ON csr.tpl_report_tag_reg_data TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.tpl_report_tag_reg_data TO tool_user;
GRANT EXECUTE ON csr.comp_requirement_report_pkg TO web_user;
GRANT EXECUTE ON csr.comp_regulation_report_pkg TO web_user;
GRANT EXECUTE ON csr.comp_requirement_report_pkg TO chain;
GRANT EXECUTE ON csr.comp_regulation_report_pkg TO chain;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_region TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_req_reg TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_regulation TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_requirement TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_tag TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.map_compliance_item TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_region TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_req_reg TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_regulation TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_requirement TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_tag TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item TO csrimp;
GRANT SELECT ON csr.compliance_item_seq TO csrimp;
grant insert on cms.doc_template to csrimp;
grant insert on cms.doc_template_file to csrimp;
grant insert on cms.doc_template_version to csrimp;
grant select on cms.doc_template_id_seq to csrimp;
grant select on cms.doc_template_file_id_seq to csrimp;




CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, ist.enable_manual_comp_date,
	   ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm,
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria, cu.user_ref
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;


BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
		 WHERE action = '/csr/site/chain/import/import.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, r.sid_id);
	END LOOP;
END;
/


INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (8, 'Emission profile export', 'Credit360.ExportImport.Export.Batched.Exporters.EmissionProfileExporter');
BEGIN
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 1, 'Fund', 1);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 2, 'Management company', 2);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 3, 'Management company contact', 3);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 4, 'Meter number', 4);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 5, 'Meter type', 5);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 6, 'Property address', 6);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 7, 'Property subtype', 7);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 8, 'Property type', 8);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES ( 9, 'Region image', 9);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos) VALUES (10, 'Region reference', 10);
END;
/
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (9, 'Factor set export', 'Credit360.ExportImport.Export.Batched.Exporters.FactorSetExporter');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Compliance Requirement Data Filter';
	v_class := 'Credit360.Compliance.Cards.ComplianceRequirementFilter';
	v_js_path := '/csr/site/compliance/requirement/filters/ComplianceRequirementFilter.js';
	v_js_class := 'Credit360.Compliance.Requirement.Filters.ComplianceRequirementFilter';
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
	
	v_desc := 'Compliance Regulation Data Filter';
	v_class := 'Credit360.Compliance.Cards.ComplianceRegulationFilter';
	v_js_path := '/csr/site/compliance/regulation/filters/ComplianceRegulationFilter.js';
	v_js_class := 'Credit360.Compliance.Regulation.Filters.ComplianceRegulationFilter';
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
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(48, 'Compliance Requirement Data Filter', 'Allows filtering of compliance requirement data', 'csr.comp_requirement_report_pkg', '/csr/site/compliance/requirement/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Compliance.Requirement.Filters.ComplianceRequirementFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Compliance Requirement Data Filter', 'csr.comp_requirement_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(49, 'Compliance Regulation Data Filter', 'Allows filtering of compliance regulation data', 'csr.comp_regulation_report_pkg', '/csr/site/compliance/regulation/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Compliance.Regulation.Filters.ComplianceRegulationFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Compliance Regulaton Data Filter', 'csr.comp_regulation_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (48, 1, 'Number of requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (49, 1, 'Number of regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (49, 2, 'Number of requirements');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (48, 1, 1, 'Requirement region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (49, 1, 1, 'Regulation region');
END;
/
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage compliance items', 0);
BEGIN
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ase', 'ASEAN (Association of Southeast Asian Nations)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('eu', 'European Union');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('gcc', 'GCC (Gulf Cooperation Council)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iae', 'IAEA (International Atomic Energy Agency)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iar', 'IARC (International Agency for Research on Cancer)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ica', 'ICAO (International Civil Aviation Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ifc', 'IFCS (International Finance Coroporation)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ilo', 'ILO (Internation Labour Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('imo', 'IMO (International Maritime Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('irp', 'IPPC (International Plant Protection Convention)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iso', 'ISO (International Organization for Standardization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('mer', 'Mercosur');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('naf', 'NAFTA (North American Free Trade Agreement)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('oce', 'OECD (Organisation for Economic Co-operation and Development)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('opc', 'OPCW (Organisation for the Prohibition of Chemical Weapons)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('osp', 'OSPAR (Convention for the Protection of the Marine Environment of the North-East Atlantic )');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('oti', 'OTIF (Intergovernmental Organisation for International Carriage by Rail)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('una', 'UNASUR (Union of South American Nations)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('une', 'UNECE (United Nations Economic Commission for Europe)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unp', 'UNEP (United Nations Environment Programme)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unc', 'UNFCCC (United Nations Framework Convention on Climate Change)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('und', 'UNIDO (United Nations Industrial Development Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unt', 'UNITAR (United Nations Institute for Training and Research)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('who', 'WHO (World Health Organisation)');
END;
/
BEGIN
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'va');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'xk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ai');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'as');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'je');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ky');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ms');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 're');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'yt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'va');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'zw');
END;
/
UPDATE csr.module
   SET module_name = 'Compliance Management', description = 'Enables the Compliance Management module. Requires Surveys and Workflow to be enabled.'
 WHERE module_id = 79;
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Meter Filter';
	v_class := 'Credit360.Metering.Cards.MeterFilter';
	v_js_path := '/csr/site/meter/filters/MeterFilter.js';
	v_js_class := 'Credit360.Metering.Filters.MeterFilter';
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
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(50, 'Meter Filter', 'Allows filtering of meters', 'csr.meter_list_pkg', '/csr/site/meter/meterList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Metering.Filters.MeterFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Meter Filter', 'csr.meter_list_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_source_type
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 50, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
		 VALUES (50, 1, 'Number of meters');
		 
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	     VALUES (50, 1, 1, 'Meter region');
END;
/
BEGIN
	UPDATE csr.std_measure_conversion
	   SET std_measure_id = 13,
	       a = 0.000000001
	 WHERE std_measure_conversion_id = 28181;
	UPDATE csr.std_measure_conversion
	   SET std_measure_id = 21
	 WHERE std_measure_conversion_id = 28182;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (21,'Start monitoring site in New Relic','Adds the site to those monitored by New Relic to diagnose performance problems and trends','AddNewRelicToSite',null);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (22,'Stop monitoring site in New Relic','Disables New Relic client-side monitoring','RemoveNewRelicFromSite',null);
END;
/
BEGIN
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_cms_template_menu			security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_cms_template_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'cms_admin_doctemplates');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'cms_admin_doctemplates',  'CMS document template manager',  '/fp/cms/admin/doctemplates/list.acds',  0, null, v_cms_template_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_cms_template_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_template_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_template_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	security.user_pkg.logonadmin;
	
END;
/
BEGIN
	INSERT INTO csr.audit_type (
		audit_type_group_id, audit_type_id, label
	) VALUES (
		1, 27, 'Batch logon'
	);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO csr.logon_type (
		logon_type_id, label
	) VALUES (
		5, 'Batch'
	);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

CREATE OR REPLACE PACKAGE csr.meter_list_pkg AS END;
/
GRANT EXECUTE ON csr.meter_list_pkg TO web_user;
GRANT EXECUTE ON csr.meter_list_pkg TO chain;
grant select,insert,update,delete on csrimp.cms_doc_template  to tool_user;
grant select,insert,update,delete on csrimp.cms_doc_template_file  to tool_user;
grant select,insert,update,delete on csrimp.cms_doc_template_version  to tool_user;

CREATE OR REPLACE PACKAGE cms.doc_template_pkg AS END;
/
GRANT EXECUTE ON cms.doc_template_pkg TO web_user;

@..\factor_pkg
@@..\issue_pkg
@@..\meter_pkg
@@..\meter_alarm_pkg
@@..\meter_monitor_pkg
@@..\csrimp\imp_pkg
@..\templated_report_pkg
@..\schema_pkg
@..\compliance_pkg
@..\tag_pkg
@..\chain\filter_pkg
@..\comp_requirement_report_pkg
@..\comp_regulation_report_pkg
@..\enable_pkg
@..\quick_survey_pkg
@..\meter_list_pkg
@..\region_metric_pkg
@..\chain\bsci_pkg
@..\chain\company_pkg
@..\chain\company_dedupe_pkg
@..\util_script_pkg
@..\..\..\aspen2\cms\db\doc_template_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\csr_data_pkg
@..\audit_pkg
@..\..\..\security\db\oracle\security_pkg
@..\..\..\security\db\oracle\user_pkg
@..\csr_user_pkg
@..\structure_import_pkg


@..\indicator_body
@..\region_body
@..\factor_body
@..\schema_body
@..\csrimp\imp_body
@@..\issue_body
@@..\audit_body
@@..\initiative_body
@@..\issue_report_body
@@..\meter_alarm_body
@@..\meter_body
@@..\meter_monitor_body
@@..\property_body
@@..\supplier_body
@@..\teamroom_body
@@..\schema_body
@@..\csrimp\imp_body
@..\templated_report_body
@..\csr_app_body
@..\factor_set_group_body
@..\compliance_body
@..\tag_body
@..\chain\filter_body
@..\comp_requirement_report_body
@..\comp_regulation_report_body
@..\enable_body
@..\quick_survey_body
@..\meter_list_body
@..\property_report_body
@..\region_metric_body
@..\chain\bsci_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\..\..\aspen2\db\aspenapp_body
@..\util_script_body
@..\..\..\aspen2\cms\db\doc_template_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\security\db\oracle\security_body
@..\..\..\security\db\oracle\user_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\csr_data_body
@..\csr_user_body
@..\chain\setup_body
@..\audit_report_body
@..\initiative_report_body
@..\meter_report_body
@..\non_compliance_report_body
@..\user_report_body
@..\delegation_body
@..\structure_import_body
@..\chain\dashboard_body



@update_tail
