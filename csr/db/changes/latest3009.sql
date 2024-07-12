define version=3009
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
CREATE SEQUENCE csr.section_fact_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOORDER
;
BEGIN
	security.user_pkg.logonadmin;
	
	--clear existing mappings (1 on live atm), they are not being used. The reason is we are going to 
	--change the way we associate tables and identify id cols
	DELETE FROM chain.dedupe_match;
	DELETE FROM chain.dedupe_merge_log;
	DELETE FROM chain.dedupe_processed_record;
	DELETE FROM chain.dedupe_rule_mapping;
	DELETE FROM chain.dedupe_rule;
	DELETE FROM chain.dedupe_mapping;
END;
/
CREATE SEQUENCE chain.dedupe_staging_link_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE chain.dedupe_staging_link(
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_staging_link_id		NUMBER NOT NULL,
	import_source_id			NUMBER NOT NULL,
	description					VARCHAR2(64) NOT NULL,
	position					NUMBER (10, 0) NOT NULL,
	staging_tab_sid				NUMBER (10, 0) NOT NULL,
	staging_id_col_sid			NUMBER (10, 0) NOT NULL,
	staging_batch_num_col_sid	NUMBER (10, 0) NULL,
	parent_staging_link_id		NUMBER (10, 0),
	destination_tab_sid			NUMBER (10, 0),
	CONSTRAINT pk_dedupe_staging_link PRIMARY KEY (app_sid, dedupe_staging_link_id),
	CONSTRAINT uc_dedupe_staging_link_pos UNIQUE (app_sid, import_source_id, position) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT uc_dedupe_staging_link_stag UNIQUE (app_sid, dedupe_staging_link_id, staging_tab_sid), --used for fk
	CONSTRAINT uc_dedupe_staging_link_dest UNIQUE (app_sid, dedupe_staging_link_id, destination_tab_sid) --used for fk
);
CREATE UNIQUE INDEX chain.uk_dedupe_staging_link_parent ON chain.dedupe_staging_link
	(app_sid, import_source_id, NVL2(parent_staging_link_id, dedupe_staging_link_id, NULL));
	
DROP TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW;
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW(
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	DEDUPE_STAGING_LINK_ID		NUMBER(10, 0) NOT NULL,
	REFERENCE					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	BATCH_NUM					NUMBER(10, 0) NULL,
	PROCESSED_DTM				DATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	MATCHED_TO_COMPANY_NAME		VARCHAR(512),
	IMPORT_SOURCE_NAME			VARCHAR(512) NOT NULL,
	CREATED_COMPANY_SID 		NUMBER(10, 0),
	CREATED_COMPANY_NAME		VARCHAR(512),
	DATA_MERGED					NUMBER(1,0),
	CMS_RECORD_ID 				NUMBER(10, 0),
	STAGING_LINK_DESCRIPTION 	VARCHAR(512)
) 
ON COMMIT DELETE ROWS;
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_COLUMN_CONFIG(
	DEDUPE_MAPPING_ID			NUMBER(10),
	SOURCE_COLUMN				VARCHAR(30),
	SOURCE_COL_SID				NUMBER(10),
	SOURCE_COL_TYPE				NUMBER(10),
	SOURCE_DATA_TYPE			VARCHAR(64),
	DESTINATION_TABLE			VARCHAR(30),
	DESTINATION_TAB_SID			NUMBER(10),
	DESTINATION_COLUMN			VARCHAR(30),
	DESTINATION_COL_SID			NUMBER(10),
	DESTINATION_COL_TYPE		NUMBER(10),
	DESTINATION_DATA_TYPE		VARCHAR(64)
) 
ON COMMIT DELETE ROWS;
CREATE SEQUENCE chain.business_rel_period_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE chain.business_relationship_period (
    app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	business_rel_period_id			NUMBER(10,0) NOT NULL,
	business_relationship_id		NUMBER(10,0) NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE,
    CONSTRAINT PK_BUSINESS_REL_PERIOD PRIMARY KEY (app_sid, business_rel_period_id),
	CONSTRAINT FK_BUS_REL_PERIOD_BUS_REL FOREIGN KEY (app_sid, business_relationship_id) REFERENCES chain.business_relationship (app_sid, business_relationship_id),
	CONSTRAINT CK_BUS_REL_PERIOD_END_DTM CHECK (end_dtm IS NULL OR end_dtm >= start_dtm)
);
create index chain.ix_bus_rel_period_bus_rel on chain.business_relationship_period (app_sid, business_relationship_id);
INSERT INTO chain.business_relationship_period (app_sid, business_rel_period_id, business_relationship_id, start_dtm, end_dtm)
	 SELECT app_sid, chain.business_rel_period_id_seq.NEXTVAL, business_relationship_id,
			CASE WHEN end_dtm IS NOT NULL AND end_dtm < start_dtm THEN end_dtm ELSE start_dtm END start_dtm, 
			end_dtm
	   FROM chain.business_relationship;
CREATE TABLE csrimp.chain_busin_relat_period (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	business_rel_period_id			NUMBER(10,0) NOT NULL,
	business_relationship_id		NUMBER(10,0) NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE,
	CONSTRAINT pk_chain_busin_relat_period PRIMARY KEY (csrimp_session_id, business_rel_period_id),
	CONSTRAINT fk_chain_busin_relat_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.map_chain_bus_rel_period (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_business_rel_period_id NUMBER(10) NOT NULL,
	new_business_rel_period_id NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_chain_bus_rel_period PRIMARY KEY (csrimp_session_id, old_business_rel_period_id) USING INDEX,
	CONSTRAINT uk_map_chain_bus_rel_period UNIQUE (csrimp_session_id, new_business_rel_period_id) USING INDEX,
	CONSTRAINT fk_map_chain_bus_rel_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.INCIDENT_TYPE(
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID                 NUMBER(10, 0)     NOT NULL,
	GROUP_KEY               VARCHAR2(255)     NOT NULL,
	LABEL                   VARCHAR2(500)     NOT NULL,
	PLURAL                  VARCHAR2(255)     NOT NULL,
	BASE_CSS_CLASS          VARCHAR2(255)     NOT NULL,
	POS                     NUMBER(10, 0)     NOT NULL,
	LIST_URL                VARCHAR2(2000)    NOT NULL,
	EDIT_URL                VARCHAR2(2000)    NOT NULL,
	NEW_CASE_URL            VARCHAR2(2000),
	MOBILE_FORM_PATH        VARCHAR2(2000),
	MOBILE_FORM_SID		    NUMBER(10, 0),
	DESCRIPTION             CLOB,
	CONSTRAINT PK_INCIDENT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, TAB_SID),
	CONSTRAINT CK_INCIDENT_MOBILE_FORM CHECK ( MOBILE_FORM_PATH IS NULL OR MOBILE_FORM_SID IS NULL ),
	CONSTRAINT FK_INCIDENT_TYPE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE TABLE CMS.ENUM_GROUP_TAB (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
	REPLACE_EXISTING_FILTERS		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_TAB PRIMARY KEY (APP_SID, TAB_SID),
	CONSTRAINT CHK_ENUM_G_TAB_REP_FILTER_1_0 CHECK (REPLACE_EXISTING_FILTERS IN (1,0)),
	CONSTRAINT FK_ENUM_GROUP_TAB_TAB FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID, TAB_SID)
);
CREATE TABLE CMS.ENUM_GROUP (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	GROUP_LABEL						VARCHAR2(255),
	CONSTRAINT PK_ENUM_GROUP PRIMARY KEY (APP_SID, ENUM_GROUP_ID),
	CONSTRAINT FK_EMUM_GROUP_ENUM_GROUP_TAB FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.ENUM_GROUP_TAB (APP_SID, TAB_SID)
);
CREATE SEQUENCE CMS.ENUM_GROUP_ID_SEQ;
CREATE TABLE CMS.ENUM_GROUP_MEMBER(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	ENUM_GROUP_MEMBER_ID	 		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_MEMBER PRIMARY KEY (APP_SID, ENUM_GROUP_ID, ENUM_GROUP_MEMBER_ID),
	CONSTRAINT FK_ENUM_GROUP_MBR_ENUM_GROUP FOREIGN KEY (APP_SID, ENUM_GROUP_ID) REFERENCES CMS.ENUM_GROUP (APP_SID, ENUM_GROUP_ID)
);
CREATE INDEX CMS.IX_ENUM_GROUP_TAB_SID ON CMS.ENUM_GROUP (APP_SID, TAB_SID);
CREATE INDEX CMS.IX_ENUM_GROUP_MEMBER_GROUP_ID ON CMS.ENUM_GROUP_MEMBER (APP_SID, ENUM_GROUP_ID);
CREATE TABLE CSRIMP.CMS_ENUM_GROUP_TAB (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
	REPLACE_EXISTING_FILTERS		NUMBER(1) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_TAB PRIMARY KEY (CSRIMP_SESSION_ID, TAB_SID),
	CONSTRAINT CHK_ENUM_G_TAB_REP_FILTER_1_0 CHECK (REPLACE_EXISTING_FILTERS IN (1,0)),
	CONSTRAINT FK_CMS_ENUM_GROUP_TAB_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CMS_ENUM_GROUP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID							NUMBER(10) NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	GROUP_LABEL						VARCHAR2(255),
	CONSTRAINT PK_ENUM_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, ENUM_GROUP_ID),
	CONSTRAINT FK_CMS_ENUM_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CMS_ENUM_GROUP_MEMBER(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ENUM_GROUP_ID					NUMBER(10) NOT NULL,
	ENUM_GROUP_MEMBER_ID	 		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ENUM_GROUP_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, ENUM_GROUP_ID, ENUM_GROUP_MEMBER_ID),
	CONSTRAINT FK_CMS_ENUM_GROUP_MEMBER_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CMS_ENUM_GROUP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ENUM_GROUP_ID				NUMBER(10) NOT NULL,
	NEW_ENUM_GROUP_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CMS_ENUM_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ENUM_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CMS_ENUM_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_ENUM_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CMS_ENUM_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
create index chain.ix_bsci_associat_company_sid_a on chain.bsci_associate (app_sid, company_sid, audit_ref);
create index chain.ix_bsci_finding_company_sid_a on chain.bsci_finding (app_sid, company_sid, audit_ref);
CREATE TABLE CHAIN.REFERENCE_COMPANY_TYPE(
	APP_SID                          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    REFERENCE_ID            		 NUMBER(10, 0)    NOT NULL,
    COMPANY_TYPE_ID					 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE PRIMARY KEY (APP_SID, REFERENCE_ID, COMPANY_TYPE_ID),
    CONSTRAINT FK_REF_CMP_TYP_CMP_TYP FOREIGN KEY (APP_SID, COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID),
    CONSTRAINT FK_REF_CMP_TYP_REF FOREIGN KEY (APP_SID, REFERENCE_ID) REFERENCES CHAIN.REFERENCE(APP_SID, REFERENCE_ID)
);
CREATE INDEX CHAIN.IX_REF_CMP_TYP_CMP_TYP ON CHAIN.REFERENCE_COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID);
CREATE TABLE CSRIMP.CHAIN_REFERENCE_COMPANY_TYPE(
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    REFERENCE_ID            		 NUMBER(10, 0)    NOT NULL,
    COMPANY_TYPE_ID					 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, REFERENCE_ID, COMPANY_TYPE_ID),
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csrimp.scenario_run_version (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	scenario_run_sid		NUMBER(10) NOT NULL,
	version					NUMBER(10) NOT NULL,
	CONSTRAINT FK_SCN_RUN_VER_IS FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);
CREATE TABLE csrimp.scenario_run_version_file (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	scenario_run_sid		NUMBER(10) NOT NULL,
	version					NUMBER(10) NOT NULL,
	file_path				VARCHAR2(4000) NOT NULL,
	sha1					RAW(20) NOT NULL,
	CONSTRAINT FK_SCN_RUN_FILE_SCN_RUN_VER_IS FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CALENDAR (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CALENDAR_SID NUMBER(10,0) NOT NULL,
	APPLIES_TO_INITIATIVES NUMBER(1,0) NOT NULL,
	APPLIES_TO_TEAMROOMS NUMBER(1,0) NOT NULL,
	DESCRIPTION VARCHAR2(255) NOT NULL,
	IS_GLOBAL NUMBER(10,0) NOT NULL,
	JS_CLASS_TYPE VARCHAR2(255) NOT NULL,
	JS_INCLUDE VARCHAR2(255) NOT NULL,
	PLUGIN_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CALENDAR PRIMARY KEY (CSRIMP_SESSION_ID, CALENDAR_SID),
	CONSTRAINT FK_CALENDAR_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CALENDAR_EVENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CALENDAR_EVENT_ID NUMBER(10,0) NOT NULL,
	CREATED_BY_SID NUMBER(10,0) NOT NULL,
	CREATED_DTM DATE NOT NULL,
	DESCRIPTION VARCHAR2(4000),
	END_DTM DATE,
	LOCATION VARCHAR2(1000),
	REGION_SID NUMBER(10,0),
	START_DTM DATE NOT NULL,
	CONSTRAINT PK_CALENDAR_EVENT PRIMARY KEY (CSRIMP_SESSION_ID, CALENDAR_EVENT_ID),
	CONSTRAINT FK_CALENDAR_EVENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CALENDAR_EVENT_INVITE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CALENDAR_EVENT_ID NUMBER(10,0) NOT NULL,
	USER_SID NUMBER(10,0) NOT NULL,
	ACCEPTED_DTM DATE,
	ATTENDED NUMBER(1,0),
	DECLINED_DTM DATE,
	INVITED_BY_SID NUMBER(10,0) NOT NULL,
	INVITED_DTM DATE NOT NULL,
	CONSTRAINT PK_CALENDAR_EVENT_INVITE PRIMARY KEY (CSRIMP_SESSION_ID, CALENDAR_EVENT_ID, USER_SID),
	CONSTRAINT FK_CALENDAR_EVENT_INVITE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CALENDAR_EVENT_OWNER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CALENDAR_EVENT_ID NUMBER(10,0) NOT NULL,
	USER_SID NUMBER(10,0) NOT NULL,
	ADDED_BY_SID NUMBER(10,0) NOT NULL,
	ADDED_DTM DATE NOT NULL,
	CONSTRAINT PK_CALENDAR_EVENT_OWNER PRIMARY KEY (CSRIMP_SESSION_ID, CALENDAR_EVENT_ID, USER_SID),
	CONSTRAINT FK_CALENDAR_EVENT_OWNER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CLIENT_UTIL_SCRIPT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CLIENT_UTIL_SCRIPT_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(2047),
	UTIL_SCRIPT_NAME VARCHAR2(255),
	UTIL_SCRIPT_SP VARCHAR2(255),
	WIKI_ARTICLE VARCHAR2(10),
	CONSTRAINT PK_CLIENT_UTIL_SCRIPT PRIMARY KEY (CSRIMP_SESSION_ID, CLIENT_UTIL_SCRIPT_ID),
	CONSTRAINT FK_CLIENT_UTIL_SCRIPT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CLIENT_UTIL_SCRIPT_PARAM (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CLIENT_UTIL_SCRIPT_ID NUMBER(10,0) NOT NULL,
	POS NUMBER(2,0) NOT NULL,
	PARAM_HIDDEN NUMBER(1,0),
	PARAM_HINT VARCHAR2(1023),
	PARAM_NAME VARCHAR2(1023) NOT NULL,
	PARAM_VALUE VARCHAR2(1024),
	CONSTRAINT PK_CLIENT_UTIL_SCRIPT_PARAM PRIMARY KEY (CSRIMP_SESSION_ID, CLIENT_UTIL_SCRIPT_ID, POS),
	CONSTRAINT FK_CLIENT_UTIL_SCRIPT_PARAM_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.UTIL_SCRIPT_RUN_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CLIENT_UTIL_SCRIPT_ID NUMBER(10,0),
	CSR_USER_SID NUMBER(10,0) NOT NULL,
	PARAMS VARCHAR2(2048),
	RUN_DTM DATE NOT NULL,
	UTIL_SCRIPT_ID NUMBER(10,0),
	CONSTRAINT FK_UTIL_SCRIPT_RUN_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CALENDAR_EVENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CALENDAR_EVENT_ID NUMBER(10) NOT NULL,
	NEW_CALENDAR_EVENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CALENDAR_EVENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CALENDAR_EVENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CALENDAR_EVENT UNIQUE (CSRIMP_SESSION_ID, NEW_CALENDAR_EVENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CALENDAR_EVENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CLIENT_UTIL_SCRIPT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CLIENT_UTIL_SCRIPT_ID NUMBER(10) NOT NULL,
	NEW_CLIENT_UTIL_SCRIPT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CLIENT_UTIL_SCRIPT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CLIENT_UTIL_SCRIPT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CLIENT_UTIL_SCRIPT UNIQUE (CSRIMP_SESSION_ID, NEW_CLIENT_UTIL_SCRIPT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CLIENT_UTIL_SCRIPT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE CSR.AUTO_IMP_IMPORTER_CMS DROP CONSTRAINT CK_AUTO_IMP_IMPORTER_SEP;
ALTER TABLE CSR.AUTO_IMP_IMPORTER_CMS ADD CONSTRAINT CK_AUTO_IMP_IMPORTER_SEP CHECK (DSV_SEPARATOR IN ('PIPE','TAB','COMMA','SEMICOLON') OR DSV_SEPARATOR IS NULL);
UPDATE csr.automated_import_class_step
  SET fileread_plugin_id = 3
 WHERE fileread_plugin_id IS NULL;
ALTER TABLE csr.automated_import_class_step
MODIFY fileread_plugin_id NOT NULL;
ALTER TABLE csr.section_module ADD (
	show_fact_icon	NUMBER(1, 0)	DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.section_module ADD (
	show_fact_icon	NUMBER(1, 0)	NULL
);
UPDATE csrimp.section_module SET show_fact_icon = 0;
ALTER TABLE csrimp.section_module MODIFY show_fact_icon NOT NULL;
ALTER TABLE csr.section_val ADD (
	entry_type	VARCHAR2(100)	DEFAULT 'MANUAL' NOT NULL
);
ALTER TABLE csr.section_val ADD CONSTRAINT CHK_SEC_VAL_ENTRY_TYPE 
	CHECK (entry_type IN ('MANUAL', 'PREVIOUS', 'INDICATOR'));
ALTER TABLE chain.dedupe_mapping ADD dedupe_staging_link_id NUMBER(10, 0) NOT NULL;
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT fk_dedupe_mapping_is;
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT uc_dedupe_mapping_col;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT uc_dedupe_mapping_tab_col UNIQUE (app_sid, dedupe_staging_link_id, tab_sid, col_sid);
ALTER TABLE chain.dedupe_mapping DROP COLUMN import_source_id;
ALTER TABLE chain.dedupe_rule DROP CONSTRAINT FK_DEDUPE_RULE_IMPORT_SOURCE;
ALTER TABLE chain.dedupe_rule DROP CONSTRAINT uc_dedupe_rule;
ALTER TABLE chain.dedupe_rule DROP COLUMN import_source_id;
ALTER TABLE chain.dedupe_rule ADD dedupe_staging_link_id NUMBER(10, 0) NOT NULL;
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT uc_dedupe_rule 
	UNIQUE (app_sid, dedupe_staging_link_id, position) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT fk_dedupe_rule_staging_link 
	FOREIGN KEY (app_sid, dedupe_staging_link_id)
	REFERENCES chain.dedupe_staging_link(app_sid, dedupe_staging_link_id);
	
ALTER TABLE chain.dedupe_processed_record RENAME COLUMN company_data_merged TO data_merged;
ALTER TABLE chain.dedupe_processed_record DROP CONSTRAINT uc_dedupe_processed_record;
ALTER TABLE chain.dedupe_processed_record DROP CONSTRAINT fk_dedupe_process_rec_source;
ALTER TABLE chain.dedupe_processed_record DROP CONSTRAINT chk_company_data_merged;
ALTER TABLE chain.dedupe_processed_record DROP COLUMN import_source_id;
ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT chk_data_merged CHECK (data_merged IN (0, 1));
ALTER TABLE chain.dedupe_processed_record ADD dedupe_staging_link_id NUMBER(10, 0);
ALTER TABLE chain.dedupe_processed_record ADD batch_num NUMBER(10, 0);
ALTER TABLE chain.dedupe_processed_record ADD cms_record_id NUMBER(10, 0);
ALTER TABLE chain.dedupe_processed_record ADD parent_processed_record_id NUMBER(10, 0);
ALTER TABLE chain.dedupe_processed_record RENAME COLUMN company_ref TO reference;
ALTER TABLE chain.dedupe_merge_log MODIFY error_message VARCHAR2(4000);
CREATE UNIQUE INDEX CHAIN.UK_DEDUPE_PROCESSED_RECORD ON CHAIN.DEDUPE_PROCESSED_RECORD
	(app_sid, dedupe_staging_link_id, reference, batch_num, iteration_num, 
		NVL2(parent_processed_record_id, dedupe_processed_record_id, NULL));
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_source
	FOREIGN KEY (app_sid, import_source_id)
	REFERENCES chain.import_source (app_sid, import_source_id);
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_parent_staging_link
	FOREIGN KEY (app_sid, parent_staging_link_id)
	REFERENCES chain.dedupe_staging_link (app_sid, dedupe_staging_link_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT fk_dedupe_mapping_stag_tab
	FOREIGN KEY (app_sid, dedupe_staging_link_id, tab_sid)
	REFERENCES chain.dedupe_staging_link (app_sid, dedupe_staging_link_id, staging_tab_sid);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT fk_dedupe_mapping_dest_tab
	FOREIGN KEY (app_sid, dedupe_staging_link_id, destination_tab_sid)
	REFERENCES chain.dedupe_staging_link (app_sid, dedupe_staging_link_id, destination_tab_sid);
ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT fk_dedupe_proc_rec_stag_ling
	FOREIGN KEY (app_sid, dedupe_staging_link_id)
	REFERENCES chain.dedupe_staging_link (app_sid, dedupe_staging_link_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_dedupe_map_dest_tab_col
	CHECK (destination_tab_sid IS NULL AND destination_col_sid IS NULL 
		OR destination_tab_sid IS NOT NULL AND destination_col_sid IS NOT NULL);
		
CREATE INDEX chain.ix_dedupe_mappin_dedupe_stagin ON chain.dedupe_mapping (app_sid, dedupe_staging_link_id, destination_tab_sid);
CREATE INDEX chain.ix_dedupe_stagin_stag_col ON chain.dedupe_staging_link (app_sid, staging_tab_sid, staging_id_col_sid);
CREATE INDEX chain.ix_dedupe_stagin_parent_stagin ON chain.dedupe_staging_link (app_sid, parent_staging_link_id);
CREATE INDEX chain.ix_dedupe_stagin_stag_tab ON chain.dedupe_staging_link (app_sid, staging_tab_sid);
CREATE INDEX chain.ix_dedupe_stagin_stag_bat_num ON chain.dedupe_staging_link (app_sid, staging_tab_sid, staging_batch_num_col_sid);
CREATE INDEX chain.ix_dedupe_stagin_destination_t ON chain.dedupe_staging_link (app_sid, destination_tab_sid);
CREATE TABLE CSRIMP.CHAIN_DEDUPE_STAGIN_LINK (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_STAGING_LINK_ID NUMBER NOT NULL,
	DESCRIPTION VARCHAR2(64) NOT NULL,
	DESTINATION_TAB_SID NUMBER(10,0),
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	PARENT_STAGING_LINK_ID NUMBER(10,0),
	POSITION NUMBER(10,0) NOT NULL,
	STAGING_BATCH_NUM_COL_SID NUMBER(10,0),
	STAGING_ID_COL_SID NUMBER(10,0) NOT NULL,
	STAGING_TAB_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_STAGIN_LINK PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_STAGING_LINK_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_STAGIN_LINK_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_STAG_LINK (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUP_STAGIN_LINK_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUP_STAGIN_LINK_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_STAG_LINK PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUP_STAGIN_LINK_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_STAG_LINK UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUP_STAGIN_LINK_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_STAG_LINK_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
ALTER TABLE csrimp.chain_dedupe_mapping ADD dedupe_staging_link_id NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedupe_mapping DROP COLUMN import_source_id;
ALTER TABLE csrimp.chain_dedupe_rule DROP COLUMN import_source_id;
ALTER TABLE csrimp.chain_dedupe_rule ADD dedupe_staging_link_id NUMBER(10, 0) NOT NULL;
ALTER TABLE csrimp.chain_dedup_proce_record RENAME COLUMN company_data_merged to data_merged;
ALTER TABLE csrimp.chain_dedup_proce_record DROP COLUMN import_source_id;
ALTER TABLE csrimp.chain_dedup_proce_record ADD dedupe_staging_link_id NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record ADD batch_num NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record ADD cms_record_id NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record ADD parent_processed_record_id NUMBER(10, 0);
ALTER TABLE csrimp.chain_dedup_proce_record RENAME COLUMN company_ref TO reference;
ALTER TABLE csrimp.chain_dedupe_merge_log MODIFY error_message VARCHAR2(4000);
grant select, insert, update, delete on csrimp.chain_dedupe_stagin_link to tool_user;
grant select, insert, update on chain.dedupe_staging_link to csrimp;
grant select on chain.dedupe_staging_link_id_seq to csrimp;
grant select on chain.dedupe_staging_link_id_seq to CSR;
UPDATE csr.est_meter
   SET meter_type = 'Other - Outdoor'
 WHERE meter_type = 'Outdoor';
 
UPDATE csr.est_meter
   SET meter_type = 'Other - Mixed Indoor/Outdoor (Water)'
 WHERE meter_type IN ('Mixed Indoor/Outdoor (Water)', 'Wastewater/Sewer', 'Indoor/Outdoor');
UPDATE csr.est_meter
   SET meter_type = 'Fuel Oil No 5 or 6'
 WHERE meter_type = 'Fuel Oil (No. 5 and No. 6)';
UPDATE csr.est_meter
   SET meter_type = 'Fuel Oil No 2'
 WHERE meter_type = 'Fuel Oil (No. 2)';
UPDATE csr.est_meter
   SET meter_type = 'Electric'
 WHERE meter_type = 'Electricity';
 
UPDATE csr.est_meter
   SET meter_type = 'Other (Energy)'
 WHERE meter_type = 'Other';
 
UPDATE csr.est_meter
   SET meter_type = 'Other - Indoor'
 WHERE meter_type = 'Indoor';
 
UPDATE csr.est_meter
   SET meter_type = 'District Chilled Water - Other'
 WHERE meter_type = 'District Chilled Water';
ALTER TABLE csr.est_meter
ADD CONSTRAINT FK_EST_METER_TYPE
FOREIGN KEY (meter_type) REFERENCES csr.est_meter_type (meter_type);
CREATE INDEX CSR.IX_EST_METER_TYPE ON CSR.EST_METER(meter_type);
ALTER TABLE chain.business_relationship ADD (
	signature						VARCHAR2(255) 
);
ALTER TABLE chain.business_relationship RENAME COLUMN start_dtm TO xxx_start_dtm;
ALTER TABLE chain.business_relationship RENAME COLUMN end_dtm TO xxx_end_dtm;
ALTER TABLE chain.business_relationship RENAME COLUMN end_reason TO xxx_end_reason;
ALTER TABLE csrimp.chain_business_relations DROP COLUMN start_dtm;
ALTER TABLE csrimp.chain_business_relations DROP COLUMN end_dtm;
ALTER TABLE csrimp.chain_business_relations DROP COLUMN end_reason;
DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner = 'CHAIN'
	   AND table_name = 'BUSINESS_RELATIONSHIP'
	   AND column_name = 'XXX_START_DTM';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.business_relationship MODIFY ( xxx_start_dtm NULL )';
	END IF;
END;
/
ALTER TABLE csr.tpl_report_schedule ADD (
	publish_to_prop_doc_lib NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_publish_to_prop_doc_lib CHECK (publish_to_prop_doc_lib IN (0, 1))
);
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT app_sid, filter_id, filter_field_id
		  FROM (
			SELECT app_sid, filter_id, filter_field_id, ROW_NUMBER() OVER (PARTITION BY app_sid, filter_id, name ORDER BY app_sid, filter_id, filter_field_id) rn
			  FROM chain.filter_field
		)
		 WHERE rn > 1
	) LOOP
		-- This cascade deletes the filter values
		DELETE FROM chain.filter_field
		 WHERE filter_field_id = r.filter_field_id
		   AND app_sid = r.app_sid;
		-- reshuffle group by indexes so there aren't any gaps
		FOR ff IN (
			SELECT filter_field_id, ROWNUM rn
			  FROM chain.filter_field
			 WHERE filter_id = r.filter_id
			   AND app_sid = r.app_sid
			   AND group_by_index IS NOT NULL
			 ORDER BY group_by_index
		) LOOP
			UPDATE chain.filter_field
			   SET group_by_index = ff.rn
			 WHERE filter_field_id = ff.filter_field_id
			   AND app_sid = r.app_sid;
		END LOOP;
	END LOOP;
END;
/
ALTER TABLE chain.filter_field ADD CONSTRAINT uk_filter_field_name UNIQUE (app_sid, filter_id, name);
ALTER TABLE chain.compound_filter ADD (
	read_only_saved_filter_sid			NUMBER(10),
	is_read_only_group_by				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_comp_fltr_is_ro_grp_by_1_0 CHECK (is_read_only_group_by IN (1, 0)),
	CONSTRAINT fk_comp_fltr_ro_saved_fltr FOREIGN KEY (app_sid, read_only_saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);
create index chain.ix_compound_filt_read_only_sav on chain.compound_filter (app_sid, read_only_saved_filter_sid);
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(table_name)
	  INTO v_check
	  FROM all_tables
	 WHERE owner = 'CSR'
	   AND table_name = 'TEMP_FLOW_ITEM_REGION';
	IF v_check = 1 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.TEMP_FLOW_ITEM_REGION';
	END IF;
END;
/
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FLOW_ITEM_REGION (
	FLOW_ITEM_ID		NUMBER(10) NOT NULL,
	REGION_SID			NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;
CREATE INDEX CSR.IX_TEMP_FLOW_ITEM_REGION_F ON CSR.TEMP_FLOW_ITEM_REGION(FLOW_ITEM_ID);
CREATE INDEX CSR.IX_TEMP_FLOW_ITEM_REGION_R ON CSR.TEMP_FLOW_ITEM_REGION(REGION_SID);
ALTER TABLE CHAIN.REFERENCE RENAME COLUMN FOR_COMPANY_TYPE_ID TO XXX_FOR_COMPANY_TYPE_ID;
INSERT INTO CHAIN.REFERENCE_COMPANY_TYPE (APP_SID, REFERENCE_ID, COMPANY_TYPE_ID)
SELECT APP_SID, REFERENCE_ID, XXX_FOR_COMPANY_TYPE_ID
  FROM CHAIN.REFERENCE R
 WHERE XXX_FOR_COMPANY_TYPE_ID IS NOT NULL
   AND NOT EXISTS(
	SELECT *
	  FROM CHAIN.REFERENCE_COMPANY_TYPE E
	 WHERE R.APP_SID = E.APP_SID
	   AND R.REFERENCE_ID = E.REFERENCE_ID
	   AND R.XXX_FOR_COMPANY_TYPE_ID = E.COMPANY_TYPE_ID
);
ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN FOR_COMPANY_TYPE_ID;

ALTER TABLE csr.PERIOD_SPAN_PATTERN
ADD PERIOD_IN_YEAR_2 NUMBER(2) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.PERIOD_SPAN_PATTERN
ADD YEAR_OFFSET_2 NUMBER(2) DEFAULT 0 NOT NULL;
DECLARE
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue'
	);
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue',
		queue_payload_type => 'csr.t_batch_job_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.batch_job_queue',
		queue_table => 'csr.batch_job_queue',
		max_retries => 2147483647
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	FOR r IN (SELECT batch_job_id
				FROM csr.batch_job
			   WHERE completed_dtm IS NULL) LOOP
		UPDATE csr.batch_job
		   SET completed_dtm = NULL,
			   processing = 0
		 WHERE batch_job_id = r.batch_job_id;
		-- queue for processing (becomes available at commit time)
		dbms_aq.enqueue(
			queue_name			=> 'csr.batch_job_queue',
			enqueue_options		=> v_enqueue_options,
			message_properties	=> v_message_properties,
 			payload				=> csr.t_batch_job_queue_entry (r.batch_job_id),
 			msgid				=> v_message_handle
 		);
	END LOOP;
	COMMIT;
END;
/

alter table csr.forecasting_email_sub rename constraint PK_FRCSTNG_EMAIL to pk_scenario_email_sub;
alter table csr.forecasting_email_sub rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_email_sub rename to scenario_email_sub;
alter table csr.scenario_email_sub drop constraint FK_FRCSTNG_EMAIL_FRCSTNG_SID;
alter table csr.scenario_email_sub rename constraint fk_frcstng_user_sid to fk_scenario_email_sub_user;
alter table csr.scenario_email_sub add constraint fk_scenario_email_sub_scenario
foreign key (app_sid, scenario_sid) references csr.scenario (app_sid, scenario_sid);
alter table csr.forecasting_scenario_alert rename constraint PK_FRCAST_SCEN_ALERT TO PK_SCENARIO_ALERT;
alter table csr.forecasting_scenario_alert rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_scenario_alert rename to scenario_alert;
ALTER TABLE CSR.SCENARIO_ALERT ADD CONSTRAINT FK_SCENARIO_ALERT_SCENARIO
FOREIGN KEY (APP_SID, SCENARIO_SID) REFERENCES CSR.SCENARIO (APP_SID, SCENARIO_SID);
ALTER TABLE CSR.SCENARIO_ALERT ADD CONSTRAINT FK_SCENARIO_ALERT_USER
FOREIGN KEY (APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);
alter table csr.forecasting_rule drop constraint fk_forecast_rule_slot_sid;
alter table csr.forecasting_rule add rule_id number(10) not null;
alter table csr.forecasting_rule drop constraint pk_forecast_rule drop index;
alter table csr.forecasting_rule rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_rule add constraint pk_forecasting_rule primary key 
(app_sid, scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm);
alter table csr.forecasting_rule add constraint fk_forecast_rule_scenario
foreign key (app_sid, scenario_sid) references csr.scenario (app_sid, scenario_sid);
drop table csr.forecasting_indicator;
drop table csr.forecasting_region;
drop table csr.forecasting_val;
drop table csr.forecasting_slot ;
alter table csr.scenario drop column scrag_test_scenario;
alter table csrimp.scenario drop column scrag_test_scenario;
alter table csrimp.scenario add (
	DATA_SOURCE_RUN_SID				NUMBER(10),
	CREATED_BY_USER_SID				NUMBER(10) NOT NULL,
	CREATED_DTM						DATE NOT NULL,
	INCLUDE_ALL_INDS				NUMBER(1) NOT NULL
);
drop table csrimp.forecasting_val;
drop table csrimp.forecasting_indicator;
drop table csrimp.forecasting_region;
alter table csrimp.forecasting_rule add rule_id number(10) not null;
alter table csrimp.forecasting_rule drop constraint pk_forecast_rule drop index;
alter table csrimp.forecasting_rule rename column forecasting_sid to scenario_sid;
alter table csrimp.forecasting_rule add constraint pk_forecasting_rule primary key 
(csrimp_session_id, scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm);
drop table csrimp.forecasting_email_sub;
CREATE TABLE CSRIMP.SCENARIO_EMAIL_SUB (
	CSRIMP_SESSION_ID			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SCENARIO_SID				NUMBER(10, 0) NOT NULL,
	CSR_USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCENARIO_EMAIL_SUB			PRIMARY KEY (CSRIMP_SESSION_ID, SCENARIO_SID, CSR_USER_SID),
	CONSTRAINT FK_SCENARIO_EMAIL_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
grant select,insert,update,delete on csrimp.scenario_email_sub to tool_user;
grant select,insert,update,delete on csrimp.forecasting_rule to tool_user;
grant select, insert, update on csr.scenario_email_sub TO csrimp;
alter table csr.scenario_run add last_run_by_user_sid number(10) default 3 not null;
alter table csr.scenario_run add constraint fk_Scenario_run_last_run_user foreign key (app_sid, last_run_by_user_sid)
references csr.csr_user (app_sid, csr_user_sid);
alter table csrimp.scenario_run add last_run_by_user_sid number(10) not null;
alter table csr.calc_job add run_by_user_sid number(10) default nvl(sys_context('SECURITY','SID'),3) not null;
alter table csr.calc_job add constraint fk_calc_job_last_run_user foreign key (app_sid, run_by_user_sid)
references csr.csr_user (app_sid, csr_user_sid);
create index csr.ix_calc_job_run_by_user_s on csr.calc_job (app_sid, run_by_user_sid);
create index csr.ix_scenario_aler_csr_user_sid on csr.scenario_alert (app_sid, csr_user_sid);
create index csr.ix_scenario_run_last_run_by_u on csr.scenario_run (app_sid, last_run_by_user_sid);
alter table csr.scenario add data_source_run_sid number(10); 
alter table csr.scenario add created_by_user_sid number(10); 
update csr.scenario set created_by_user_sid  = 3;
alter table csr.scenario modify created_by_user_sid not null;
alter table csr.scenario modify created_by_user_sid default sys_context('security', 'sid') ;
alter table csr.scenario add created_dtm date default sysdate not null;
alter table csr.scenario add include_all_inds number(1) ;
update csr.scenario set include_all_inds = 0;
alter table csr.scenario modify include_all_inds not null;
alter table csr.scenario add constraint ck_scenario_include_all_inds check (include_all_inds in (0,1));
alter table csr.scenario drop constraint ck_scenario_recalc_trig_type;
alter table csr.scenario add CONSTRAINT CK_SCENARIO_RECALC_TRIG_TYPE CHECK (RECALC_TRIGGER_TYPE IN (0, 1, 2));
alter table csr.scenario drop constraint CK_SCENARIO_DATA_SOURCE ;
alter table csr.scenario add
    CONSTRAINT CK_SCENARIO_DATA_SOURCE CHECK(
        (DATA_SOURCE IN (0, 1) AND DATA_SOURCE_SP IS NULL AND DATA_SOURCE_SP_ARGS IS NULL AND DATA_SOURCE_RUN_SID IS NULL) OR
        (DATA_SOURCE = 2 AND DATA_SOURCE_SP IS NOT NULL AND DATA_SOURCE_SP_ARGS IS NOT NULL AND DATA_SOURCE_RUN_SID IS NULL) OR
		(DATA_SOURCE = 3 AND DATA_SOURCE_SP IS NULL AND DATA_SOURCE_SP_ARGS IS NULL AND DATA_SOURCE_RUN_SID IS NOT NULL)
    );
BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE csr.calendar_event_type';
EXCEPTION
	WHEN OTHERS THEN
		-- 942 = table or view does not exist
		IF SQLCODE <> -942 THEN
			RAISE;
		END IF;
END;
/
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.ia_type_survey RENAME TO internal_audit_type_survey';
EXCEPTION
	WHEN OTHERS THEN
		-- 942 = table or view does not exist
		IF SQLCODE <> -942 THEN
			RAISE;
		END IF;
END;
/
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.non_com_typ_rpt_audi_typ RENAME TO non_comp_type_rpt_audit_type';
EXCEPTION
	WHEN OTHERS THEN
		-- 942 = table or view does not exist
		IF SQLCODE <> -942 THEN
			RAISE;
		END IF;
END;
/
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'AGGREGATE_IND_GROUP'
	   AND column_name = 'RUN_FOR_CURRENT_MONTH';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD RUN_FOR_CURRENT_MONTH NUMBER(1) DEFAULT 0 NOT NULL';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD CONSTRAINT CK_AGG_IND_GROUP_MONTHLY CHECK (RUN_FOR_CURRENT_MONTH IN (0, 1))';
	END IF;
END;
/
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'AGGREGATE_IND_GROUP'
	   AND column_name = 'RUN_FOR_CURRENT_MONTH';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP ADD RUN_FOR_CURRENT_MONTH NUMBER(1) NOT NULL';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP ADD CONSTRAINT CK_AGG_IND_GROUP_MONTHLY CHECK (RUN_FOR_CURRENT_MONTH IN (0, 1))';
	END IF;
END;
/
BEGIN
	FOR r IN (
		SELECT COUNT(tc.column_name) c_check, t.owner, t.table_name
		  FROM all_tables t
	 LEFT JOIN all_tab_columns tc 
				 ON t.owner = tc.owner
				AND t.table_name = tc.table_name
				AND tc.column_name = 'TIME_SPENT_IND_SID'
		 WHERE t.owner IN ('CSR', 'CSRIMP')
		   AND t.table_name = 'FLOW_STATE'
	  GROUP BY t.owner, t.table_name
	)
	LOOP
		IF r.c_check = 0 THEN
			EXECUTE IMMEDIATE 'ALTER TABLE ' || r.owner || '.flow_state ADD time_spent_ind_sid NUMBER(10)';
		END IF;
	END LOOP;
END;
/
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name) INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'FLOW_STATE'
	   AND constraint_name = 'FK_FLOW_STATE_TIME_IND_SID';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_STATE ADD CONSTRAINT FK_FLOW_STATE_TIME_IND_SID FOREIGN KEY (APP_SID, TIME_SPENT_IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID)';
		EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_flow_state_time_ind_sid ON csr.flow_state (app_sid, time_spent_ind_sid)';
	END IF;
END;
/
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'SUPPLIER'
	   AND table_name = 'GT_TARGET_SCORES'
	   AND column_name = 'APP_SID'
	   AND nullable = 'Y';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.GT_TARGET_SCORES MODIFY APP_SID NOT NULL';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'SUPPLIER'
	   AND table_name = 'GT_TARGET_SCORES'
	   AND column_name = 'GT_PRODUCT_TYPE_ID'
	   AND nullable = 'Y';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.GT_TARGET_SCORES MODIFY GT_PRODUCT_TYPE_ID NOT NULL';
	END IF;
END;
/

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='SCENARIO_RUN' and column_name='LAST_RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.scenario_run add last_run_by_user_sid number(10) default 3 not null';
		execute immediate 'alter table csr.scenario_run add constraint fk_Scenario_run_last_run_user foreign key (app_sid, last_run_by_user_sid) references csr.csr_user (app_sid, csr_user_sid)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='SCENARIO_RUN'  and column_name='LAST_RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.scenario_run add last_run_by_user_sid number(10) not null';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='CALC_JOB'  and column_name='RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.calc_job add run_by_user_sid number(10) default nvl(sys_context(''SECURITY'',''SID''),3) not null';
		execute immediate 'alter table csr.calc_job add constraint fk_calc_job_last_run_user foreign key (app_sid, run_by_user_sid) references csr.csr_user (app_sid, csr_user_sid)';
	end if;
	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_CALC_JOB_RUN_BY_USER_S';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_calc_job_run_by_user_s on csr.calc_job (app_sid, run_by_user_sid)';
	end if;
	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_SCENARIO_ALER_CSR_USER_SID';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_scenario_aler_csr_user_sid on csr.scenario_alert (app_sid, csr_user_sid)';
	end if;
	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_SCENARIO_RUN_LAST_RUN_BY_U';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_scenario_run_last_run_by_u on csr.scenario_run (app_sid, last_run_by_user_sid)';
	end if;
end;
/

alter table csr.forecasting_rule drop constraint fk_forecast_rule_scenario;
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.FORECASTING_RULE ADD CONSTRAINT FK_FORECAST_RULE_SCENARIO_RULE FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID) REFERENCES CSR.SCENARIO_RULE (APP_SID, SCENARIO_SID, RULE_ID)';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-02275: such a referential constraint already exists in the table
		IF SQLCODE != -2275 THEN
			RAISE;
		END IF;
END;
/

create index csr.ix_scenario_data_source_run on csr.scenario (app_sid, data_source_run_sid);

alter table csr.scenario add constraint fk_scenario_data_source_run foreign key (app_sid, data_source_run_sid)
references csr.scenario_run (app_sid, scenario_run_sid);

grant select, insert, update on chain.dedupe_staging_link to CSR;
grant select on chain.dedupe_staging_link_id_seq to CSR;
GRANT SELECT ON chain.business_rel_period_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON chain.business_relationship_period TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_busin_relat_period TO tool_user;
GRANT SELECT ON chain.business_relationship_period TO csr;
grant select,insert,update,delete on csrimp.incident_type to tool_user;
grant insert on csr.incident_type to csrimp;
grant select on cms.enum_group_id_seq to csrimp;
grant insert on cms.enum_group_tab to csrimp;
grant insert on cms.enum_group to csrimp;
grant insert on cms.enum_group_member to csrimp;
CREATE OR REPLACE PACKAGE csr.region_report_pkg AS
END;
/
GRANT EXECUTE ON csr.region_report_pkg TO web_user;
GRANT EXECUTE ON csr.region_report_pkg TO chain;
grant select on chain.reference_company_type to CSR;
grant select, insert, update, delete on csrimp.chain_reference_company_type to tool_user;
grant insert on chain.reference_company_type to csrimp;
GRANT INSERT,SELECT ON csr.scenario_run_version TO csrimp;
GRANT INSERT,SELECT ON csr.scenario_run_version_file TO csrimp;
grant select, insert, update, delete on csrimp.calendar to tool_user;
grant select, insert, update, delete on csrimp.calendar_event to tool_user;
grant select, insert, update, delete on csrimp.calendar_event_invite to tool_user;
grant select, insert, update, delete on csrimp.calendar_event_owner to tool_user;
grant select, insert, update, delete on csrimp.client_util_script to tool_user;
grant select, insert, update, delete on csrimp.client_util_script_param to tool_user;
grant select, insert, update, delete on csrimp.util_script_run_log to tool_user;
grant select, insert, update on csr.calendar to csrimp;
grant select, insert, update on csr.calendar_event to csrimp;
grant select, insert, update on csr.calendar_event_invite to csrimp;
grant select, insert, update on csr.calendar_event_owner to csrimp;
grant select, insert, update on csr.client_util_script to csrimp;
grant select, insert, update on csr.client_util_script_param to csrimp;
grant select, insert, update on csr.util_script_run_log to csrimp;
grant select on csr.calendar_event_id_seq to csrimp;
grant select on csr.client_util_script_id_seq to csrimp;


ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_tab
	FOREIGN KEY (app_sid, staging_tab_sid)
	REFERENCES cms.tab (app_sid, tab_sid);
	
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_col
	FOREIGN KEY (app_sid, staging_tab_sid, staging_id_col_sid)
	REFERENCES cms.tab_column (app_sid, tab_sid, column_sid);
	
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_batch_col
	FOREIGN KEY (app_sid, staging_tab_sid, staging_batch_num_col_sid)
	REFERENCES cms.tab_column (app_sid, tab_sid, column_sid);
	
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_dest_tab
	FOREIGN KEY (app_sid, destination_tab_sid)
	REFERENCES cms.tab (app_sid, tab_sid);


CREATE OR REPLACE VIEW csr.v$corp_rep_capability AS
	SELECT sec.app_sid, sec.section_sid, fsrc.flow_capability_id,
	   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
	   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM csr.section sec
	  JOIN csr.section_module secmod ON sec.app_sid = secmod.app_sid
	   AND sec.module_root_sid = secmod.module_root_sid 
	  JOIN csr.flow_item fi ON sec.app_sid = fi.app_sid 
	   AND sec.flow_item_id = fi.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid 
	   AND fi.current_state_id = fsrc.flow_state_id  
	  LEFT JOIN csr.region_role_member rrm ON sec.app_sid = rrm.app_sid 
	   AND secmod.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN csr.superadmin sa ON sa.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE sec.active = 1
	   AND (rrm.role_sid IS NOT NULL OR sa.csr_user_sid IS NOT NULL)
	 GROUP BY sec.app_sid, sec.section_sid, fsrc.flow_capability_id;
create or replace view cms.fk as
select fkc.app_sid, fkc.fk_cons_id, fkc.tab_sid fk_tab_sid, fkt.oracle_schema owner, fkc.constraint_name, fkt.oracle_table table_name, fktc.oracle_column column_name,
       ukc.uk_cons_id, ukc.tab_sid r_tab_sid, ukt.oracle_schema r_owner, ukt.oracle_table r_table_name, uktc.oracle_column r_column_name,
       fkcc.pos
  from cms.fk_cons fkc, cms.fk_cons_col fkcc,
       cms.uk_cons ukc, cms.uk_cons_col ukcc,
       cms.tab_column fktc, cms.tab_column uktc,
       cms.tab fkt, cms.tab ukt
 where fkc.fk_cons_id = fkcc.fk_cons_id and fkc.r_cons_id = ukc.uk_cons_id and
       ukc.uk_cons_id = ukcc.uk_cons_id and fkcc.pos = ukcc.pos and
       fkcc.column_sid = fktc.column_sid and ukcc.column_sid = uktc.column_sid and
       fktc.tab_sid = fkt.tab_sid and uktc.tab_sid = ukt.tab_sid
order by fkt.tab_sid, fkc.fk_cons_id, fkcc.pos;
	 
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
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
		   ncst.format_mask nc_score_format_mask,
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
	 
insert into csr.app_lock (app_sid, lock_type) select app_sid, 4 from csr.customer;
commit;
begin
update csr.batched_import_type set assembly='Credit360.ExportImport.Import.Batched.Importers.ForecastingScenarioImporter' 
where batch_import_type_id=4;
update csr.batched_export_type set assembly='Credit360.ExportImport.Export.Batched.Exporters.ForecastingScenarioExporter'
where batch_export_type_id=15;
end;
/




INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (21, 'corpreporter', 'Edit indicator fact', 1, 0);
	
INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (22, 'corpreporter', 'Clear indicator fact', 1, 0);
	
UPDATE csr.flow_alert_class
   SET on_save_helper_sp = 'csr.flow_pkg.OnCreateSupplierFlowHelpers'
 WHERE flow_alert_class = 'supplier';
 
INSERT INTO csr.batched_import_type (batch_import_type_id,label,assembly) VALUES (5,'Factor set import','Credit360.ExportImport.Import.Batched.Importers.FactorSetImporter');

BEGIN
	INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
	VALUES (301, 'Automated import change', 1);
END;
/
BEGIN
  security.user_pkg.logonadmin('');	
  UPDATE csr.ind
     SET IS_SYSTEM_MANAGED = 1
   WHERE parent_sid IN (SELECT app_sid FROM csr.customer);
END;
/
BEGIN
	UPDATE chain.capability 
	   SET capability_name = 'Update company business relationship periods'
	 WHERE capability_name = 'Terminate company business relationships';
	UPDATE chain.capability
	   SET capability_name = 'Update company business relationship periods (supplier => purchaser)'
	 WHERE capability_name = 'Terminate company business relationships (supplier => purchaser)';
	COMMIT;
END;
/
BEGIN
	FOR r IN (
		SELECT br.business_relationship_id, br.business_relationship_type_id || ':' || listagg(brc.company_sid, ',') WITHIN GROUP (order by brt.tier) signature
		  FROM chain.business_relationship br
		  JOIN chain.business_relationship_company brc ON brc.business_relationship_id = br.business_relationship_id AND brc.app_sid = br.app_sid
		  JOIN chain.business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id AND brt.app_sid = brc.app_sid
		 GROUP BY br.business_relationship_id, br.business_relationship_type_id
	) LOOP
		UPDATE chain.business_relationship
		   SET signature = r.signature
		 WHERE business_relationship_id = r.business_relationship_id;
	END LOOP;
	COMMIT;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Clean up duplicate filter values
	DELETE FROM chain.filter_value fv
	 WHERE EXISTS (
		SELECT app_sid, filter_value_id 
		  FROM (
			SELECT app_sid, filter_value_id, 
				   ROW_NUMBER() OVER 
				   (PARTITION BY app_sid, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, 
				    max_num_val, compound_filter_id_value, saved_filter_sid_value, period_set_id, period_interval_id, start_period_id, filter_type, null_filter 
					ORDER BY app_sid, filter_value_id) rn
			 FROM chain.filter_value
		 )
	 	 WHERE rn > 1 
		   AND app_sid = fv.app_sid 
		   AND filter_value_id = fv.filter_value_id
	);
END;
/
UPDATE csr.util_script_param
   SET param_hint = 'System ID of a workflow. Supports Chain, Campaign and CMS workflow types only.'
 WHERE util_script_id = 27;
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Activity Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ActivityFilter';
	v_js_path := '/csr/site/chain/cards/filters/activityFilter.js';
	v_js_class := 'Chain.Cards.Filters.ActivityFilter';
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
	
	v_desc := 'Activity Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ActivityFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/activityFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ActivityFilterAdapter';
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
		VALUES(52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 'Activity Filter', 'Allows filtering of activities', 'chain.activity_report_pkg', '/csr/site/chain/activities/activityList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Activity Filter', 'chain.activity_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with chain
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 0);
	END LOOP;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Activity Filter Adapter', 'chain.activity_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 1 /*chain.activity_report_pkg.AGG_TYPE_COUNT*/, 'Number of activities');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 1 /*chain.activity_report_pkg.COL_TYPE_SUPPLIER_REGION*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Supplier region');
	
	INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name) 
	VALUES (4, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, 'company');
END;
/
UPDATE csr.capability 
   SET description = 'Data Explorer: Displays checkboxes in Data Explorer allowing users to display the percentage or absolute variances between periods on charts (either between consecutive periods or between a specified baseline period and each subsequent period).'
 WHERE name = 'Enable Dataview Bar Variance Options';
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Region Filter';
	v_class := 'Credit360.Schema.Cards.RegionFilter';
	v_js_path := '/csr/site/schema/indRegion/list/filters/RegionFilter.js';
	v_js_class := 'Credit360.Region.Filters.RegionFilter';
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
		VALUES (51, 'Region Filter', 'Allows filtering of regions', 'csr.region_report_pkg', '/csr/site/schema/indRegion/list/List.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Region.Filters.RegionFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Region Filter', 'csr.region_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 51, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (51, 1, 'Number of regions');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (51, 1, 1, 'Region');
END;
/
BEGIN
	INSERT INTO csr.util_script (
	  util_script_id, util_script_name, description, util_script_sp, wiki_article
	) VALUES (
	  28, 'Clear last used measure conversions', 'Clears all last used measure conversions for the specified user. See wiki about functioning of last used measure conversion.',
	  'ClearLastUsdMeasureConversions', 'W1179'
	);
	INSERT INTO csr.util_script_param (
	  util_script_id, param_name, param_hint, pos
	) VALUES (
	  28, 'User SID', 'SID', 0
	);
END;
/
DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'bidvest';
DELETE FROM csr.branding
 WHERE client_folder_name = 'bidvest';
INSERT INTO CSR.PERIOD_SPAN_PATTERN_TYPE (PERIOD_SPAN_PATTERN_TYPE_ID, LABEL)
VALUES (4, 'Offset to Offset');
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(util_script_id) INTO v_check
	  FROM csr.util_script
	 WHERE util_script_id = 27
	   AND util_script_name = 'Capture time in workflow states';
	
	IF v_check = 0 THEN
		INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
		VALUES (27, 'Capture time in workflow states', 'Creates indicators for each state in given workflow and record the time items spend in each state.', 'RecordTimeInFlowStates', NULL);
		INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) 
		VALUES (27, 'Workflow SID', 'System ID of a workflow. Supports Chain and Campaign workflow types only.', 0, NULL, 0);
	END IF;
	   
END;
/




CREATE OR REPLACE PACKAGE cms.testdata_pkg
IS
	NULL;
END;
/
GRANT EXECUTE ON cms.testdata_pkg TO csr;
CREATE OR REPLACE PACKAGE cms.testdata_pkg
IS
	NULL;
END;
/
GRANT EXECUTE ON cms.testdata_pkg TO csr;
create or replace package chain.activity_report_pkg as
procedure dummy;
end;
/
create or replace package body chain.activity_report_pkg as
procedure dummy
as
begin
	null;
end;
end;
/
grant execute on chain.activity_report_pkg to web_user;
CREATE OR REPLACE PACKAGE csr.flow_report_pkg as
	PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.flow_report_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/
GRANT EXECUTE ON csr.flow_report_pkg to web_user;


@..\section_pkg
@..\section_root_pkg
@..\csr_data_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\schema_pkg
@..\chain\company_dedupe_pkg
@..\chain\test_chain_utils_pkg
@..\automated_import_pkg
@..\enable_pkg
@..\..\..\aspen2\cms\db\testdata_pkg
@..\testdata_pkg
@..\batch_job_pkg
@..\chain\business_relationship_pkg
@..\chain\chain_pkg
@..\chain\chain_link_pkg
@..\csrimp\imp_pkg
@..\templated_report_schedule_pkg
@..\flow_report_pkg
@..\chain\activity_report_pkg
@..\chain\company_filter_pkg
@..\chain\company_user_pkg
@..\chain\filter_pkg
@..\delegation_pkg
@@..\chain\filter_pkg
@@..\region_report_pkg
@..\util_script_pkg
@..\chain\helper_pkg
@@..\schema_pkg
@..\forecasting_pkg
@..\scenario_pkg
@..\stored_calc_datasource_pkg
@..\supplier_pkg


@..\section_body
@..\section_root_body
@..\csrimp\imp_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\energy_star_body
@..\energy_star_job_body
@..\..\..\aspen2\cms\db\tab_body
@..\schema_body
@..\chain\company_dedupe_body
@..\chain\test_chain_utils_body
@..\property_body
@..\audit_body
@..\factor_body
@..\automated_import_body
@..\testdata_body
@..\enable_body
@..\..\..\aspen2\cms\db\testdata_body
@..\batch_job_body
@..\csr_app_body
@..\tag_body
@..\chain\business_relationship_body
@..\chain\chain_body
@..\chain\chain_link_body
@..\measure_body
@..\property_report_body
@..\templated_report_schedule_body
@..\..\..\aspen2\cms\db\filter_body
@..\chain\filter_body
@..\flow_report_body
@..\user_report_body
@..\indicator_body
@..\region_body
@..\delegation_body
@..\factor_set_group_body
@..\chain\activity_report_body
@..\chain\company_filter_body
@..\chain\company_user_body
@..\quick_survey_body
@@..\region_report_body
@..\csr_data_body
@..\util_script_body
@@..\initiative_metric_body
@@..\enable_body
@..\chain\helper_body
@..\chain\report_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\higg_setup_body
@@..\schema_body
@@..\csrimp\imp_body
@..\automated_export_body
@..\scenario_body
@..\forecasting_body
@..\csr_user_body
@..\actions\scenario_body
@..\stored_calc_datasource_body
@..\doc_folder_body
@..\supplier_body
@..\aggregate_ind_body
@..\chain\bsci_body


@update_tail
