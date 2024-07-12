define version=3102
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

CREATE TABLE csr.COMPLIANCE_ROLLOUT_REGIONS
  (
    APP_SID            NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    COMPLIANCE_ITEM_ID NUMBER(10) NOT NULL,
    REGION_SID        NUMBER(10,0) NOT NULL,
    CONSTRAINT PK_COMPLIANCE_ROLLOUT_REGIONS PRIMARY KEY (APP_SID,COMPLIANCE_ITEM_ID,REGION_SID)
  );

CREATE TABLE csrimp.compliance_rollout_regions(
                csrimp_session_id                           NUMBER(10)     DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
                compliance_item_id                       NUMBER(10) NOT NULL,
                region_sid                                                           NUMBER(10,0) NOT NULL, 
                CONSTRAINT pk_compliance_rollout_regions PRIMARY KEY (csrimp_session_id, compliance_item_id, region_sid)
);

create index csr.ix_compliance_ro_region_sid on csr.compliance_rollout_regions (app_sid, region_sid);

-- Alter tables

ALTER TABLE csr.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_reg_comp_item
                FOREIGN KEY (app_sid, compliance_item_id)
                REFERENCES csr.compliance_item (app_sid, compliance_item_id);

ALTER TABLE csr.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_regions_region
                FOREIGN KEY (app_sid, region_sid)
                REFERENCES csr.region(app_sid, region_sid);
                
ALTER TABLE csrimp.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_regions_is 
                FOREIGN KEY (csrimp_session_id)
                REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
				
grant select, insert, update, delete on csrimp.compliance_rollout_regions to tool_user;
grant insert on csr.compliance_rollout_regions TO csrimp;

CREATE SEQUENCE CSR.AUTO_IMP_PRODUCT_SETTINGS_SEQ;
CREATE TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUTO_IMP_PRODUCT_SETTINGS_ID	NUMBER(10) NOT NULL,
	AUTOMATED_IMPORT_CLASS_SID		NUMBER(10) NOT NULL,
	STEP_NUMBER						NUMBER(10) NOT NULL,
	MAPPING_XML						SYS.XMLTYPE NOT NULL,
	AUTOMATED_IMPORT_FILE_TYPE_ID	NUMBER(10) NOT NULL,
	DSV_SEPARATOR					CHAR,
	DSV_QUOTES_AS_LITERALS			NUMBER(1),
	EXCEL_WORKSHEET_INDEX			NUMBER(10),
	ALL_OR_NOTHING					NUMBER(1),
	HEADER_ROW						NUMBER(10),
	CONCATENATOR					CHAR,
	DEFAULT_COMPANY_SID				NUMBER(10),
	COMPANY_MAPPING_TYPE_ID			NUMBER(10),
	PRODUCT_MAPPING_TYPE_ID			NUMBER(10) NOT NULL,
	PRODUCT_TYPE_MAPPING_TYPE_ID	NUMBER(10) NOT NULL,
	CMS_MAPPING_XML					SYS.XMLTYPE,
	TAB_SID							NUMBER(10),
	CONSTRAINT PK_AUTO_IMP_PRODUCT_SETTINGS PRIMARY KEY (AUTO_IMP_PRODUCT_SETTINGS_ID),
	CONSTRAINT UK_AUTO_IMP_PRODUCT_SETTINGS UNIQUE (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER),
	CONSTRAINT CK_AUTO_IMP_PRODUCT_SETTINGS CHECK (
		(COMPANY_MAPPING_TYPE_ID IS NULL AND DEFAULT_COMPANY_SID IS NOT NULL)
		OR COMPANY_MAPPING_TYPE_ID IS NOT NULL),
	CONSTRAINT CK_AUTO_IMP_PRODUCT_CMS CHECK (
		(CMS_MAPPING_XML IS NULL AND TAB_SID IS NULL)
		OR (CMS_MAPPING_XML IS NOT NULL AND TAB_SID IS NOT NULL))
);

CREATE SEQUENCE CSR.COMPLIANCE_PERMIT_SCORE_ID_SEQ;
CREATE TABLE CSR.COMPLIANCE_PERMIT_SCORE (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COMPLIANCE_PERMIT_SCORE_ID		NUMBER(10, 0)	NOT NULL,
	COMPLIANCE_PERMIT_ID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	SCORE							NUMBER(15, 5),
	COMMENT_TEXT					CLOB,
	SET_DTM							DATE			DEFAULT TRUNC(SYSDATE) NOT NULL,
	CHANGED_BY_USER_SID				NUMBER(10, 0),
	VALID_UNTIL_DTM					DATE,
	SCORE_SOURCE_TYPE				NUMBER(10, 0),
	SCORE_SOURCE_ID					NUMBER(10, 0),
	IS_OVERRIDE						NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_COMPIANCE_PERMIT_SCORE PRIMARY KEY (APP_SID, COMPLIANCE_PERMIT_SCORE_ID),
	CONSTRAINT UK_SUPPLIER_RELATIONSHIP_SCORE UNIQUE (APP_SID, COMPLIANCE_PERMIT_ID, SET_DTM, IS_OVERRIDE),
	CONSTRAINT CHK_COMP_PERM_SCORE_SET_DTM CHECK (SET_DTM = TRUNC(SET_DTM)),
	CONSTRAINT CHK_COMP_PERM_SCORE_VLD_DTM CHECK (VALID_UNTIL_DTM = TRUNC(VALID_UNTIL_DTM)),
	CONSTRAINT CHK_IS_OVERRIDE CHECK (IS_OVERRIDE IN (0,1))
);
CREATE INDEX csr.ix_perm_score_perm ON csr.compliance_permit_score (app_sid, compliance_permit_id);
CREATE INDEX csr.ix_perm_score_type ON csr.compliance_permit_score (app_sid, score_type_id);
CREATE INDEX csr.ix_perm_score_csr_user ON csr.compliance_permit_score (app_sid, changed_by_user_sid);
CREATE INDEX csr.ix_perm_score_threshold ON csr.compliance_permit_score (app_sid, score_threshold_id);
CREATE UNIQUE INDEX csr.ix_perm_score_view ON csr.compliance_permit_score (app_sid, compliance_permit_id, score_type_id, set_dtm, is_override);
CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_SCORE (
	CSRIMP_SESSION_ID 				NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_PERMIT_SCORE_ID		NUMBER(10, 0)	NOT NULL,
	COMPLIANCE_PERMIT_ID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	SCORE							NUMBER(15, 5),
	COMMENT_TEXT					CLOB,
	SET_DTM							DATE			NOT NULL,
	CHANGED_BY_USER_SID				NUMBER(10, 0),
	VALID_UNTIL_DTM					DATE,
	SCORE_SOURCE_TYPE				NUMBER(10, 0),
	SCORE_SOURCE_ID					NUMBER(10, 0),
	IS_OVERRIDE						NUMBER(1)		NOT NULL,
	LAST_PERMIT_SCORE_LOG_ID 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_COMPL_PERMIT_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_PERMIT_SCORE_ID),
	CONSTRAINT FK_COMPL_PERMIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_COMPLIANCE_PERMIT_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIANCE_PERMIT_SCORE PRIMARY KEY (OLD_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIANCE_PERMIT_SCORE UNIQUE (NEW_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLI_PERMIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.compliance_permit_header (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    CONSTRAINT pk_permit_header  PRIMARY KEY (app_sid, plugin_id),
    CONSTRAINT ck_permit_header_plugin_type CHECK (plugin_type_id = 22)
);
CREATE INDEX ix_compli_permit_hdr_plugin ON csr.compliance_permit_header (plugin_id, plugin_type_id);
ALTER TABLE csr.compliance_permit_header ADD CONSTRAINT fk_compli_permit_hdr_plugin
    FOREIGN KEY (plugin_id, plugin_type_id)
    REFERENCES csr.plugin(plugin_id, plugin_type_id);
CREATE TABLE csr.compliance_permit_header_group (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_header_group PRIMARY KEY (app_sid, plugin_id, group_sid),
    CONSTRAINT ck_permit_hdr_group_grp_role CHECK (
		(group_sid IS NULL AND role_sid IS NOT NULL) OR 
		(group_sid IS NOT NULL AND role_sid IS NULL)
	)
);
CREATE INDEX csr.ix_compliance_permit_hdr_role ON csr.compliance_permit_header_group (app_sid, role_sid);
ALTER TABLE csr.compliance_permit_header_group ADD CONSTRAINT fk_compliance_permit_hdr_group
    FOREIGN KEY (app_sid, plugin_id)
    REFERENCES csr.compliance_permit_header (app_sid, plugin_id);
ALTER TABLE csr.compliance_permit_header_group ADD CONSTRAINT fk_compliance_permit_hdr_role
    FOREIGN KEY (app_sid, role_sid)
    REFERENCES csr.role (app_sid, role_sid);
CREATE TABLE csrimp.compliance_permit_header(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    plugin_type_id    				NUMBER(10, 0)	NOT NULL,
    pos               				NUMBER(10, 0)	NOT NULL,
    CONSTRAINT pk_permit_header PRIMARY KEY (csrimp_session_id, plugin_id),
    CONSTRAINT fk_permit_header_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.compliance_permit_header_group (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    plugin_id         				NUMBER(10, 0)	NOT NULL,
    group_sid						NUMBER(10, 0),
    role_sid						NUMBER(10, 0),
    CONSTRAINT pk_permit_header_group PRIMARY KEY (csrimp_session_id, plugin_id, group_sid),
    CONSTRAINT fk_permit_header_group_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE CHAIN.DD_CUSTOMER_BLCKLST_EMAIL(
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	EMAIL_DOMAIN				VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DD_CUSTOMER_BLCKLST_EMAIL PRIMARY KEY(APP_SID, EMAIL_DOMAIN)
);

CREATE TABLE CHAIN.DD_DEF_BLCKLST_EMAIL(
	EMAIL_DOMAIN				VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DD_DEF_BLCKLST_EMAIL PRIMARY KEY (EMAIL_DOMAIN)
);

CREATE TABLE CSRIMP.CHAIN_DD_CUST_BLCKLST_EMAIL(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	EMAIL_DOMAIN				VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_CHAIN_DD_CUST_BLCKLST_EML PRIMARY KEY(CSRIMP_SESSION_ID, EMAIL_DOMAIN)
);

CREATE SEQUENCE SURVEYS.SURVEY_RESPONSE_SEQ;
CREATE SEQUENCE SURVEYS.RESPONSE_SUBMISSION_SEQ;
CREATE SEQUENCE SURVEYS.SURVEY_ANSWER_SEQ;
ALTER TABLE SURVEYS.QUESTION ADD (
	DELETED_DTM						DATE NULL,
	CONSTRAINT CHK_QUEST_DELETED_0_1 CHECK ((MATRIX_PARENT_ID IS NULL AND DELETED_DTM IS NULL) OR (MATRIX_PARENT_ID IS NOT NULL AND (DELETED_DTM IS NULL OR DELETED_DTM IS NOT NULL)))
);
ALTER TABLE SURVEYS.SURVEY_SECTION_QUESTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SSQ_DELETED_0_1 CHECK (DELETED IN (0,1))
);
ALTER TABLE SURVEYS.SURVEY_SECTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SS_DELETED_0_1 CHECK (DELETED IN (0,1))
);
ALTER TABLE SURVEYS.QUESTION_OPTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QO_DELETED_0_1 CHECK (DELETED IN (0,1))
);
CREATE TABLE SURVEYS.ANSWER(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_ID 					NUMBER(10, 0) 	NOT NULL,
	SUBMISSION_ID 				NUMBER(10, 0) 	NOT NULL,
	QUESTION_ID 				NUMBER(10, 0) 	NOT NULL,
	QUESTION_VERSION 			NUMBER(10, 0) 	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 1 NOT NULL,
	QUESTION_OPTION_ID 			NUMBER(10, 0) 	NULL,
	REPEAT_INDEX 				NUMBER(10, 0) 	NULL,
	BOOLEAN_VALUE 				NUMBER(1) 		NULL,
	NUMERIC_VALUE 				NUMBER		 	NULL,
	TEXT_VALUE_SHORT 			VARCHAR2(4000)  NULL,
	TEXT_VALUE_LONG 			CLOB			NULL,
	DATE_VALUE					DATE 			NULL,
	CONSTRAINT PK_SURVEY_ANSWER PRIMARY KEY (APP_SID, ANSWER_ID, SUBMISSION_ID),
	CONSTRAINT CHK_ANSWER_BOOLEAN_VALUE CHECK (BOOLEAN_VALUE IN (0,1)),
	CONSTRAINT CHK_SURVEY_ANSWER_VALUE CHECK ((TEXT_VALUE_SHORT IS NOT NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NOT NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NOT NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NOT NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NOT NULL))
);
ALTER TABLE SURVEYS.ANSWER ADD 
	CONSTRAINT UK_ANSWER_SUBMISSION UNIQUE (APP_SID, SUBMISSION_ID, QUESTION_ID)
;
ALTER TABLE SURVEYS.ANSWER MODIFY QUESTION_DRAFT DEFAULT NULL;
CREATE TABLE SURVEYS.RESPONSE(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	RESPONSE_ID 				NUMBER(10, 0)   NOT NULL,
	CONSTRAINT PK_SURVEY_RESPONSE PRIMARY KEY (APP_SID, RESPONSE_ID)
)
;
ALTER TABLE SURVEYS.RESPONSE ADD
	CREATED_BY_USER_SID 		NUMBER(10, 0)	NULL
;
ALTER TABLE SURVEYS.RESPONSE ADD
	LATEST_SUBMISSION_ID		NUMBER(10, 0)	NULL
;
ALTER TABLE SURVEYS.RESPONSE ADD
	DRAFT		NUMBER(1)		NULL
;
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE SURVEYS.RESPONSE
	   SET CREATED_BY_USER_SID = 3
	 WHERE CREATED_BY_USER_SID IS NULL;
	UPDATE SURVEYS.RESPONSE
	   SET DRAFT = 1
	 WHERE DRAFT IS NULL;
END;
/
ALTER TABLE SURVEYS.RESPONSE MODIFY CREATED_BY_USER_SID NOT NULL;
ALTER TABLE SURVEYS.RESPONSE MODIFY DRAFT NOT NULL;
CREATE TABLE SURVEYS.RESPONSE_SUBMISSION(
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	RESPONSE_ID					NUMBER(10) NOT NULL,
	SUBMISSION_ID				NUMBER(10) NOT NULL,
	SUBMITTED_DTM				DATE,
	SUBMITTED_BY_USER_SID		NUMBER(10),
	CONSTRAINT PK_SURVEY_RESPONSE_SUBMISSION PRIMARY KEY (APP_SID, SUBMISSION_ID)
)
;


ALTER TABLE chain.product_supplier ADD (
	is_active					NUMBER(1) DEFAULT 0 NOT NULL
);
UPDATE chain.product_supplier SET is_active = 1;
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scrag_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.scrag_queue'
	);
	COMMIT;
END;
/
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.scragpp_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.scragpp_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.scragpp_queue'
	);
	COMMIT;
END;
/
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.est_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.est_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table => 'csr.est_queue'
	);
	COMMIT;
END;
/
drop type csr.t_scrag_queue_entry;
drop type csr.t_batch_job_queue_entry;
drop type csr.t_est_queue_entry;
drop package aspen2.timezone_pkg;
drop TABLE ASPEN2.TIMEZONES_MAP_CLDR_TO_WIN;
drop TABLE ASPEN2.TIMEZONES_WIN_TO_CLDR;
DROP INDEX CSR.UK_CI_LOOKUP_KEY;
CREATE UNIQUE INDEX CSR.UK_CI_LOOKUP_KEY ON CSR.COMPLIANCE_ITEM (APP_SID,NVL(LOOKUP_KEY, 'COMP_ITEM_' || COMPLIANCE_ITEM_ID));
DROP INDEX csr.ix_tag_grp_mem_tag;
ALTER TABLE CSR.TAG_GROUP_MEMBER ADD CONSTRAINT UK_TAG_GROUP_MEMBER UNIQUE (APP_SID, TAG_ID);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_SETTINGS_STEP
	FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
	REFERENCES CSR.AUTOMATED_IMPORT_CLASS_STEP(APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_SET_FILETYPE
	FOREIGN KEY (AUTOMATED_IMPORT_FILE_TYPE_ID)
	REFERENCES CSR.AUTOMATED_IMPORT_FILE_TYPE(AUTOMATED_IMPORT_FILE_TYPE_ID);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_PROD_MAP
	FOREIGN KEY (PRODUCT_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_COMP_MAP
	FOREIGN KEY (COMPANY_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_TYPE_MAP
	FOREIGN KEY (PRODUCT_TYPE_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_CMS_TAB
	FOREIGN KEY (APP_SID, TAB_SID)
	REFERENCES CMS.TAB(APP_SID, TAB_SID);
create index csr.ix_auto_imp_prod_automated_imp on csr.auto_imp_product_settings (automated_import_file_type_id);
create index csr.ix_auto_imp_prod_product_type_ on csr.auto_imp_product_settings (product_type_mapping_type_id);
create index csr.ix_auto_imp_prod_tab_sid on csr.auto_imp_product_settings (app_sid, tab_sid);
create index csr.ix_auto_imp_prod_company_mappi on csr.auto_imp_product_settings (company_mapping_type_id);
create index csr.ix_auto_imp_prod_product_mappi on csr.auto_imp_product_settings (product_mapping_type_id);
ALTER TABLE csr.auto_imp_user_imp_settings ADD set_line_mngmnt_frm_mngr_key NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.auto_imp_user_imp_settings ADD CONSTRAINT ck_auto_imp_usr_set_lin_mngmnt CHECK (set_line_mngmnt_frm_mngr_key IN (0,1));
ALTER TABLE csr.compliance_permit_condition ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_cpc_copied_from 
		FOREIGN KEY (app_sid, copied_from_id) 
		REFERENCES csr.compliance_permit_condition (app_sid, compliance_item_id)
);
ALTER TABLE csr.issue ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_issue_copied_from
		FOREIGN KEY (app_sid, issue_id)
		REFERENCES csr.issue (app_sid, issue_id)
);
ALTER TABLE csr.issue_scheduled_task ADD (
	copied_from_id					NUMBER(10) NULL,
	CONSTRAINT fk_issue_st_copied_from
		FOREIGN KEY (app_sid, copied_from_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);
ALTER TABLE csrimp.compliance_permit_condition ADD (
	copied_from_id					NUMBER(10) NULL
);
ALTER TABLE csrimp.issue ADD (
	copied_from_id					NUMBER(10) NULL
);
ALTER TABLE csrimp.issue_scheduled_task ADD (
	copied_from_id					NUMBER(10) NULL
);
CREATE INDEX csr.ix_cpc_copied_from ON csr.compliance_permit_condition(app_sid, copied_from_id);
CREATE INDEX csr.ix_issue_copied_from ON csr.issue (app_sid, copied_from_id);
CREATE INDEX csr.ix_issue_st_copied_from ON csr.issue_scheduled_task (app_sid, copied_from_id);
begin
	for r in (select 1 from all_indexes where index_name = 'UK_FACTOR_1' and owner='CSR') loop
		execute immediate 'DROP INDEX CSR.UK_FACTOR_1';
	end loop;
end;
/
CREATE UNIQUE INDEX CSR.UK_FACTOR_1 ON CSR.FACTOR (
 APP_SID, FACTOR_TYPE_ID, NVL(GEO_COUNTRY, 'XX'), NVL(GEO_REGION, 'XX'), NVL(EGRID_REF, 'XX'), NVL(REGION_SID, -1), START_DTM, END_DTM, GAS_TYPE_ID,
  NVL(std_factor_id, -is_selected), NVL(custom_factor_id, -is_selected)
);
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_COMPL_PERM
	FOREIGN KEY (APP_SID, COMPLIANCE_PERMIT_ID)
	REFERENCES CSR.COMPLIANCE_PERMIT (APP_SID, COMPLIANCE_PERMIT_ID);
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_SCORE_TYPE 
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE(APP_SID, SCORE_TYPE_ID);
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_SCORE_THRSH 
	FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
	REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID);
	
ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE ADD CONSTRAINT FK_COMPL_PERM_SCRE_CSR_USER 
	FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);
	
ALTER TABLE csr.score_type ADD (
	applies_to_permits				NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT ck_score_type_app_to_perm CHECK (applies_to_permits IN (0, 1))
);
ALTER TABLE csrimp.score_type ADD (
	applies_to_permits				NUMBER(1, 0) NOT NULL
);
ALTER TABLE csr.internal_audit ADD (
	permit_id		NUMBER(10, 0),
	CONSTRAINT FK_IA_COMPL_PERMIT FOREIGN KEY (APP_SID, PERMIT_ID) REFERENCES CSR.COMPLIANCE_PERMIT (APP_SID, COMPLIANCE_PERMIT_ID)
);
create index csr.ix_internal_audi_permit_id on csr.internal_audit (app_sid, permit_id);
ALTER TABLE csrimp.internal_audit ADD (
	permit_id		NUMBER(10, 0)
);
ALTER TABLE csr.internal_audit_type_group ADD (
	applies_to_permits		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_iatg_appl_to_permits CHECK (applies_to_permits IN (0,1))
);
begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_IATG_MUST_APPL_TO_STHNG') loop
		execute immediate 'ALTER TABLE csr.internal_audit_type_group DROP CONSTRAINT CK_IATG_MUST_APPL_TO_STHNG';
	end loop;
end;
/
ALTER TABLE csr.internal_audit_type_group ADD (
	CONSTRAINT CK_IATG_MUST_APPL_TO_STHNG CHECK (applies_to_regions = 1 OR applies_to_users = 1 OR applies_to_permits = 1)
);
ALTER TABLE csrimp.internal_audit_type_group ADD (
	applies_to_permits		NUMBER(1) NOT NULL
);
	
ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN MATCH_EVERY_CATEGORY;
ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN COMMENTS_DISPLAY_TYPE;
ALTER TABLE SURVEYS.QUESTION_VERSION ADD DEFAULT_DATE_VALUE DATE;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_SUBMISSION_ANSWER
	FOREIGN KEY (APP_SID, SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION(APP_SID, SUBMISSION_ID)
;
ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_SURVEY
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION(APP_SID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_ANSWER_QUESTION_VERSION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_ANSWER_Q_OPTION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_OPTION(APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD CONSTRAINT FK_SUBMISSION_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;
ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_SUBMISSION
	FOREIGN KEY (APP_SID, LATEST_SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION (APP_SID, SUBMISSION_ID)
;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD SIMPLE_INFO_TEXT VARCHAR2(4000);
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD LABEL_X VARCHAR2(1024);
UPDATE SURVEYS.SURVEY_SECTION_TR set LABEL_X = LABEL;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR DROP COLUMN LABEL;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR RENAME COLUMN LABEL_X TO LABEL;
DROP SEQUENCE SURVEYS.SURVEY_SECTION_ID_SEQ;
DROP SEQUENCE SURVEYS.SURVEY_QUESTION_ID_SEQ;


exec dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '255.255.255.255:998', 'connect,resolve' );
grant execute on chain.setup_pkg to web_user;
GRANT SELECT ON CSR.COMPLIANCE_PERMIT_SCORE_ID_SEQ TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_permit_score TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_permit_score TO tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_header to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_header_group to tool_user;
grant select, insert, update on csr.compliance_permit_header to csrimp;
grant select, insert, update on csr.compliance_permit_header_group to csrimp;
grant select, insert, update on chain.filter_page_column to csr;
GRANT SELECT, INSERT, UPDATE ON CHAIN.DD_CUSTOMER_BLCKLST_EMAIL TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.CHAIN_DD_CUST_BLCKLST_EMAIL TO TOOL_USER;
GRANT SELECT, INSERT ON CHAIN.DD_CUSTOMER_BLCKLST_EMAIL TO CSR;
GRANT SELECT ON CHAIN.DD_DEF_BLCKLST_EMAIL TO CSR;
grant select, references ON csr.csr_user TO surveys;


	
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD CONSTRAINT FK_SUBMISSION_USER
	FOREIGN KEY (APP_SID, SUBMITTED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_CREATED_USER
	FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
CREATE INDEX surveys.ix_response_created_by_us ON surveys.response (app_sid, created_by_user_sid);
CREATE INDEX surveys.ix_response_subm_submitted_by_ ON surveys.response_submission (app_sid, submitted_by_user_sid);


CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.internal_audit_type_source_id audit_type_source_id,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename, cast(act.icon_image_sha1  as varchar2(40)) icon_image_sha1,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, act.is_failure,
		   sqs.survey_sid summary_survey_sid, sqs.label summary_survey_label, ssr.survey_version summary_survey_version, ia.summary_response_id,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, iat.form_sid,
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask, ia.permit_id,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = ssr.app_sid
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON NVL(ssr.survey_sid, iat.summary_survey_sid) = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;
/***********************************************************************
	v$current_raw_compl_perm_score - the current non-overridden (raw) compliance permit score
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_raw_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 0
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 0
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);
/***********************************************************************
	v$current_ovr_compl_perm_score - the current overridden compliance permit score
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_ovr_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 1
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 1
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);
		
/***********************************************************************
	v$current_compl_perm_score_all - the current raw compliance permit score and corresponding overrides
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_compl_perm_score_all AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   MAX(compliance_permit_score_id) raw_compliance_permit_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   --
		   MAX(ovr_compliance_permit_score_id) ovr_compliance_permit_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id
	  FROM (
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   compliance_permit_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, 
				   --
				   NULL ovr_compliance_permit_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id
			  FROM v$current_raw_compl_perm_score
			 UNION ALL
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   NULL compliance_permit_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, 
				   --
				   compliance_permit_score_id ovr_compliance_permit_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override,
				   set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, 
				   score_source_id ovr_score_source_id
			  FROM v$current_ovr_compl_perm_score
	)
	GROUP BY compliance_permit_id, score_type_id; 
/***********************************************************************
	v$current_compl_perm_score - the current returns overridden if set / raw if not
***********************************************************************/
CREATE OR REPLACE VIEW csr.v$current_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score, ovr_score_source_id, raw_score_source_id) score_source_id
	  FROM v$current_compl_perm_score_all;
	  
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.detailed_help_link, qv.action
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid
	  WHERE q.matrix_parent_id is null;
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments,
		qv.detailed_help_link, qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft;




BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, 1 /*chain.product_supplier_report_pkg.AGG_TYPE_COUNT*/, 'Number of suppliers');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/
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
		
			-- Read/write for admins at top level
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
				in_ace_flags				=> security.security_pkg.ACE_FLAG_DEFAULT,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			-- Read/write for EHS Managers at documents level
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
				in_ace_flags				=> security.security_pkg.ACE_FLAG_DEFAULT,
				in_sid_id					=> v_ehs_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			-- Read/write for Property Manager at documents level
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
				in_ace_flags				=> security.security_pkg.ACE_FLAG_DEFAULT,
				in_sid_id					=> v_prop_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			-- Read only for other users (property workflow permission check will also apply)
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			-- read/inheritable at documents level
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_folder_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_DEFAULT,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ
			);
			
			-- read/not inheritable at doc lib level (so they can't access trash)
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> 0, -- Not inheritable,
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
	DELETE FROM csr.util_script_param 
	 WHERE util_script_id = 35;
	DELETE FROM csr.util_script_run_log 
	 WHERE util_script_id = 35;
	DELETE FROM csr.util_script 
	 WHERE util_script_id = 35;
	INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
	VALUES (35, 'Create user profiles for CSR users', 'Creates profiles for all non super admin user accounts that don''t yet have one - User_ref must be set.', 'CreateProfilesForUsers', NULL);
END;
/
CREATE OR REPLACE TYPE CSR.T_USER_PROFILE_STAGED_ROW AS 
	OBJECT (
	PRIMARY_KEY						VARCHAR2(256),
	EMPLOYEE_REF					VARCHAR2(128),
	PAYROLL_REF						NUMBER(10),
	FIRST_NAME						VARCHAR2(256),
	LAST_NAME						VARCHAR2(256),
	MIDDLE_NAME						VARCHAR2(256),
	FRIENDLY_NAME					VARCHAR2(256),
	EMAIL_ADDRESS					VARCHAR2(256),
	USERNAME						VARCHAR2(256),
	WORK_PHONE_NUMBER				VARCHAR2(32),
	WORK_PHONE_EXTENSION			VARCHAR2(8),
	HOME_PHONE_NUMBER				VARCHAR2(32),
	MOBILE_PHONE_NUMBER				VARCHAR2(32),
	MANAGER_EMPLOYEE_REF			VARCHAR2(128),
	MANAGER_PAYROLL_REF				NUMBER(10),
	MANAGER_PRIMARY_KEY				VARCHAR2(128),
	EMPLOYMENT_START_DATE			DATE,
	EMPLOYMENT_LEAVE_DATE			DATE,
	PROFILE_ACTIVE					NUMBER(1),
	DATE_OF_BIRTH					DATE,
	GENDER							VARCHAR2(8),
	JOB_TITLE						VARCHAR2(128),
	CONTRACT						VARCHAR2(256),
	EMPLOYMENT_TYPE					VARCHAR2(256),
	PAY_GRADE						VARCHAR2(256),
	BUSINESS_AREA_REF				VARCHAR2(256),
	BUSINESS_AREA_CODE				NUMBER(10),
	BUSINESS_AREA_NAME				VARCHAR2(256),
	BUSINESS_AREA_DESCRIPTION		VARCHAR2(1024),
	DIVISION_REF					VARCHAR2(256),
	DIVISION_CODE					NUMBER(10),
	DIVISION_NAME					VARCHAR2(256),
	DIVISION_DESCRIPTION			VARCHAR2(1024),
	DEPARTMENT						VARCHAR2(256),
	NUMBER_HOURS					NUMBER(10),
	COUNTRY							VARCHAR2(128),
	LOCATION						VARCHAR2(256),
	BUILDING						VARCHAR2(256),
	COST_CENTRE_REF					VARCHAR2(256),
	COST_CENTRE_CODE				NUMBER(10),
	COST_CENTRE_NAME				VARCHAR2(256),
	COST_CENTRE_DESCRIPTION			VARCHAR2(1024),
	WORK_ADDRESS_1					VARCHAR2(256),
	WORK_ADDRESS_2					VARCHAR2(256),
	WORK_ADDRESS_3					VARCHAR2(256),
	WORK_ADDRESS_4					VARCHAR2(256),
	HOME_ADDRESS_1					VARCHAR2(256),
	HOME_ADDRESS_2					VARCHAR2(256),
	HOME_ADDRESS_3					VARCHAR2(256),
	HOME_ADDRESS_4					VARCHAR2(256),
	LOCATION_REGION_REF				VARCHAR(1024),
	INTERNAL_USERNAME				VARCHAR2(256),
	MANAGER_USERNAME				VARCHAR2(256),
	ACTIVATE_ON						DATE,
	DEACTIVATE_ON					DATE,
	INSTANCE_STEP_ID				NUMBER(10),
	LAST_UPDATED_DTM				DATE,
	LAST_UPDATED_USER_SID			NUMBER(10),
	LAST_UPDATE_METHOD				VARCHAR(256),
	ERROR_MESSAGE					VARCHAR(1024)
	);
/
INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
	VALUES (7, 'Compliance product importer', 'Credit360.ExportImport.Automated.Import.Importers.ProductImporter.ProductImporter');
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (98, 'HR integration', 'EnableHrIntegration', 'Enables/disables the HR integration.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (98, 'Enable/Disable', 0, '0=disable, 1=enable');
END;
/
BEGIN
	-- Update affected meters to generic "other" types
	-- (there were onlt 2 affected meters on live at the time of writing this script)
	UPDATE csr.est_meter
	   SET meter_type = 'Other - Indoor'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Indoor';
	UPDATE csr.est_meter
	   SET meter_type = 'Other - Mixed Indoor/Outdoor (Water)'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Mixed Indoor/Outdoor';
	UPDATE csr.est_meter
	   SET meter_type = 'Other - Outdoor'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Outdoor';
	-- Remove the old meter type mappings
	DELETE FROM csr.est_conv_mapping
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );
	DELETE FROM csr.est_meter_type_mapping
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );
	-- Insert the new meter types
	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Indoor');
	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Mixed Indoor/Outdoor');
	
	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Outdoor');
	-- Switch out the conversions, use them for the new meter types as the
	-- UOMs are the same for the new meter types as the ones being removed
	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Indoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Indoor';
	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Mixed Indoor/Outdoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Mixed Indoor/Outdoor';
	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Outdoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Outdoor';
	-- Remove the old meter types
	DELETE FROM csr.est_meter_type
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );
END;
/
BEGIN
	-- Remove disused metrics (we might not have all of these in our system)
	DELETE FROM csr.est_building_metric_mapping
	 WHERE metric_name IN (
	 	'alternativeWaterGeneratedOnsiteMixedUse',
	 	'alternativeWaterGeneratedOnsiteTotalUse',
	 	'alternativeWaterGeneratedOnsiteIndoorUse',
	 	'alternativeWaterGeneratedOnsiteOutdoorUse',
	 	'alternativeWaterGeneratedOnsiteTotalCost',
	 	'alternativeWaterGeneratedOnsiteMixedCost',
	 	'alternativeWaterGeneratedOnsiteIndoorCost',
	 	'alternativeWaterGeneratedOnsiteOutdoorCost',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteMixedUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteIndoorUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteOutdoorUse'
	);
	DELETE FROM csr.est_attr_for_building
	 WHERE attr_name IN (
	 	'alternativeWaterGeneratedOnsiteMixedUse',
	 	'alternativeWaterGeneratedOnsiteTotalUse',
	 	'alternativeWaterGeneratedOnsiteIndoorUse',
	 	'alternativeWaterGeneratedOnsiteOutdoorUse',
	 	'alternativeWaterGeneratedOnsiteTotalCost',
	 	'alternativeWaterGeneratedOnsiteMixedCost',
	 	'alternativeWaterGeneratedOnsiteIndoorCost',
	 	'alternativeWaterGeneratedOnsiteOutdoorCost',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteMixedUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteIndoorUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteOutdoorUse'
	);
END;
/
DECLARE
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Metric Value Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductMetricValFilter';
	v_js_path := '/csr/site/chain/cards/filters/productMetricValFilter.js';
	v_js_class := 'Chain.Cards.Filters.ProductMetricValFilter';
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
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 'Product Metric Value Filter', 'Allows filtering of product metric values.', 'chain.product_metric_report_pkg', '/csr/site/chain/products/productMetricValList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductMetricValFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Metric Value Filter', 'chain.product_metric_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 1 /*chain.product_metric_report_pkg.AGG_TYPE_COUNT_METRIC_VAL*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 2 /*chain.product_metric_report_pkg.AGG_TYPE_SUM_METRIC_VAL*/, 'Sum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 3 /*chain.product_metric_report_pkg.AGG_TYPE_AVG_METRIC_VAL*/, 'Average of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 4 /*chain.product_metric_report_pkg.AGG_TYPE_MAX_METRIC_VAL*/, 'Maximum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 5 /*chain.product_metric_report_pkg.AGG_TYPE_MIN_METRIC_VAL*/, 'Minimum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 19, 'Product Metric', '/csr/site/chain/manageProduct/controls/ProductMetricValTab.js', 'Chain.ManageProduct.ProductMetricValTab', 'Credit360.Chain.Plugins.ProductMetricValPlugin', 'Product Metric tab.');
UPDATE security.menu
   SET description = 'Settings'
 WHERE action = '/csr/site/compliance/ConfigureSettings.acds';
	
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit audit tab', '/csr/site/compliance/controls/AuditList.js', 'Credit360.Compliance.Controls.AuditList', 'Credit360.Compliance.Plugins.AuditListPlugin', 'Shows permit audits.');
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (22, 'Permit tab header');
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 22, 'Permit score', '/csr/site/compliance/permits/ScoreHeader.js', 'Credit360.Compliance.Permits.ScoreHeader', 'Credit360.Compliance.Plugins.ScoreHeaderDto', 'This header shows some stuff.');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_group_id		  chain.card_group.card_group_id%TYPE;
BEGIN
	v_desc := 'Permit Audit Filter Adapter';
	v_class := 'Credit360.Compliance.Cards.PermitAuditFilterAdapter';
	v_js_path := '/csr/site/compliance/filters/permitAuditFilterAdapter.js';
	v_js_class := 'Credit360.Compliance.Filters.PermitAuditFilterAdapter';
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
			'Permit Audit Filter Adapter',
			'csr.permit_helper_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Compliance Permit Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	FOR r IN (SELECT app_sid FROM csr.compliance_options WHERE permit_flow_sid IS NOT NULL)
	LOOP
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditDtm','Date',1,75,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'label','Label',2,130,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'internalAuditTypeLabel','Audit type',3,100,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyScore','Survey score',4,90,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'flowStateLabel','Status',5,80,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditClosureTypeLabel','Result',6,80,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'openNonCompliances','Open findings',7,60,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyCompleted','Survey submitted',8,110,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorFullName','Audit coordinator',9,100,0,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'regionDescription','Region',10,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'internalAuditSid','ID',11,75,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'regionPath','Region path',12,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'ncScore','Finding score',13,60,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'surveyLabel','Survey',14,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorName','Auditor',15,100,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorOrganisation','Auditor Organisation',16,120,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'auditorCompany','Auditor Company',17,120,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'notes','Notes',18,130,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'createdDtm','Created date',19,75,1,'csr_site_compliance_auditlist_');
		
		INSERT INTO CHAIN.FILTER_PAGE_COLUMN (APP_SID,CARD_GROUP_ID,COLUMN_NAME,LABEL,POS,WIDTH,HIDDEN,SESSION_PREFIX)
		VALUES (r.app_sid,41,'nextAuditDueDtm','Expiry date',20,75,1,'csr_site_compliance_auditlist_');
	END LOOP;
END;
/
DECLARE
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Supplier Metric Value Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierMetricValFilter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierMetricValFilter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierMetricValFilter';
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
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(63 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 'Product Supplier Metric Value Filter', 'Allows filtering of product supplier metric values.', 'chain.prdct_supp_mtrc_report_pkg', '/csr/site/chain/products/productSupplierMetricValList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierMetricValFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Suppplier Metric Value Filter', 'chain.prdct_supp_mtrc_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 63 /*chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (63 /*chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL*/, 1 /*chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_COUNT_METRIC_VAL*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (63 /*chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL*/, 2 /*chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_SUM_METRIC_VAL*/, 'Sum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (63 /*chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL*/, 3 /*chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_AVG_METRIC_VAL*/, 'Average of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (63 /*chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL*/, 4 /*chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_MAX_METRIC_VAL*/, 'Maximum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (63 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 5 /*chain.product_metric_report_pkg.AGG_TYPE_MIN_METRIC_VAL*/, 'Minimum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 20, 'Product Supplier Metric', '/csr/site/chain/manageProduct/controls/ProductSupplierMetricValTab.js', 'Chain.ManageProduct.ProductSupplierMetricValTab', 'Credit360.Chain.Plugins.ProductSupplierMetricValPlugin', 'Product Supplier Metric tab.');
BEGIN
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('example');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('gmail');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('googlemail');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('yahoo');
END;
/
	
BEGIN	
	INSERT INTO chain.dd_customer_blcklst_email (app_sid, email_domain)
	SELECT co.app_sid, ddc.email_domain 
	  FROM chain.customer_options co
	  CROSS JOIN chain.dd_def_blcklst_email ddc
	 WHERE co.enable_dedupe_preprocess = 1;
END;
/
UPDATE surveys.question_type
   SET question_type = 'fileupload',
       label = 'File upload'
 WHERE question_type = 'files'
;
UPDATE surveys.question_type
   SET question_type = 'matrixsimple',
       label = 'Simple matrix'
 WHERE question_type = 'matrix'
;
UPDATE surveys.question_type
   SET question_type = 'matrixrow',
       label = 'Matrix row'
 WHERE question_type = 'radiorow'
;
DELETE FROM surveys.question_type WHERE question_type = 'slider';
DECLARE
	v_class_id 		security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	
	BEGIN
		security.class_pkg.CreateClass(
			in_act_id			=> v_act,
			in_parent_class_id	=> NULL,
			in_class_name		=> 'QuestionLibrary',
			in_helper_pkg		=> NULL,
			in_helper_prog_id	=> NULL,
			out_class_id		=> v_class_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_class_id := security.class_pkg.GetClassID('QuestionLibrary');
	END;
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 65536, -- question_library_pkg.PERMISSION_APPROVE_QUESTION
			in_permission_name		=> 'Approve question'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	security.user_pkg.LogOff(v_act);
END;
/

insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (CSR.PLUGIN_ID_SEQ.nextval, 1, 'Compliance Tab', '/csr/site/property/properties/controls/ComplianceTab.js', 'Controls.ComplianceTab', 'Credit360.Property.Plugins.CompliancePlugin', 'Shows Compliance Legal Register.');

BEGIN
	INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
	VALUES (36, 'permit', 'Surrendered Acknowledged');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

@..\batch_trigger_vsel
	
@../schema_pkg
@../schema_body
@../enable_body
@../chain/company_body
@../chain/company_dedupe_pkg
@../chain/company_dedupe_body
@../chain/dedupe_preprocess_pkg
@../chain/dedupe_preprocess_body
@../chain/setup_body
@../csrimp/imp_body


CREATE OR REPLACE PACKAGE chain.product_metric_report_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.product_metric_report_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/
GRANT EXECUTE ON chain.product_metric_report_pkg TO cms;
GRANT EXECUTE ON chain.product_metric_pkg TO csr;
CREATE OR REPLACE PACKAGE chain.prdct_supp_mtrc_report_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.prdct_supp_mtrc_report_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/
GRANT EXECUTE ON chain.prdct_supp_mtrc_report_pkg TO cms;
GRANT EXECUTE ON chain.prdct_supp_mtrc_report_pkg TO csr;
CREATE OR REPLACE PACKAGE csr.integration_api_pkg AS END;
/
GRANT EXECUTE ON csr.integration_api_pkg TO web_user;


@..\chain\company_product_pkg
@..\chain\product_supplier_report_pkg
@..\chain\product_report_pkg
@..\stored_calc_datasource_pkg
@..\energy_star_job_pkg
@..\batch_job_pkg
@..\user_profile_pkg
@..\util_script_pkg
@..\permit_pkg
@..\automated_import_pkg
@..\chain\company_pkg
@..\chain\product_type_pkg
grant execute on aspen2.tr_pkg to web_user;
@..\enable_pkg
@..\chain\chain_pkg
@..\chain\filter_pkg
@..\chain\product_metric_report_pkg
@..\schema_pkg
@..\csr_data_pkg
@..\quick_survey_pkg
@..\audit_helper_pkg
@..\audit_pkg
@..\permit_report_pkg
@..\chain\prdct_supp_mtrc_report_pkg
--@..\surveys\survey_pkg
--@..\surveys\question_library_pkg
@..\integration_api_pkg
@..\chain\company_user_pkg
@../compliance_register_report_pkg
@../compliance_pkg
@../chain/company_dedupe_pkg
@../chain/dedupe_preprocess_pkg

@../chain/dedupe_preprocess_body
@../chain/setup_body
@../csrimp/imp_body
@../issue_report_body
@../flow_body
@../compliance_setup_body
@../compliance_register_report_body
@..\chain\company_product_body
@..\chain\product_supplier_report_body
@..\compliance_library_report_body
@..\chain\product_report_body
@..\permit_body
@..\enable_body
@..\stored_calc_datasource_body
@..\energy_star_job_body
@..\batch_job_body
@..\degreedays_body
@..\user_report_body
@..\user_profile_body
@..\util_script_body
@..\delegation_body
@..\sheet_body
@..\..\..\aspen2\cms\db\pivot_body
@..\automated_import_body
@..\chain\company_body
@..\chain\product_type_body
@..\doc_folder_body
@..\chain\plugin_body
@..\chain\product_metric_report_body
@..\csrimp\imp_body
@..\issue_body
@..\schema_body
@..\csr_app_body
@..\quick_survey_body
@..\audit_helper_body
@..\flow_body
@..\audit_body
@..\permit_report_body
@..\audit_report_body
@..\chain\company_dedupe_body
@..\chain\test_chain_utils_body
@..\chain\prdct_supp_mtrc_report_body
--@..\surveys\survey_body
--@..\surveys\question_library_body
--@..\surveys\question_library_report_body
@..\permission_body
@..\integration_api_body
@..\chain\company_user_body
@..\chain\type_capability_body
@..\chain\company_filter_body
@../compliance_body


@update_tail
