define version=2989
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
CREATE TABLE CHAIN.DEDUPE_MERGE_LOG(
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_MERGE_LOG_ID				NUMBER(10, 0) NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID 		NUMBER(10, 0) NOT NULL,
	DEDUPE_FIELD_ID					NUMBER(10, 0),
	REFERENCE_ID 					NUMBER(10, 0),
	TAG_GROUP_ID 					NUMBER(10, 0),
	OLD_VAL							VARCHAR2(4000),
	NEW_VAL							VARCHAR2(4000),
	CONSTRAINT PK_DEDUPE_MERGE_LOG PRIMARY KEY (APP_SID, DEDUPE_MERGE_LOG_ID),
	CONSTRAINT CHK_DEDUPE_MERGE_FLD_REF_TAG CHECK 
		((DEDUPE_FIELD_ID IS NOT NULL AND REFERENCE_ID IS NULL AND TAG_GROUP_ID IS NULL) 
		OR (DEDUPE_FIELD_ID IS NULL AND REFERENCE_ID IS NOT NULL AND TAG_GROUP_ID IS NULL)
		OR (DEDUPE_FIELD_ID IS NULL AND REFERENCE_ID IS NULL AND TAG_GROUP_ID IS NOT NULL))
);
CREATE SEQUENCE CHAIN.DEDUPE_MERGE_LOG_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_VAL_CHANGE AS 
  OBJECT ( 
	MAPPING_FIELD_ID	NUMBER(10),
	OLD_VAL 			VARCHAR2(4000),
	NEW_VAL 			VARCHAR2(4000)
  );
/
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_VAL_CHANGE_TABLE AS
 TABLE OF T_DEDUPE_VAL_CHANGE;
/ 
CREATE TABLE CSRIMP.CHAIN_DEDUPE_MERGE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_MERGE_LOG_ID NUMBER(10,0) NOT NULL,
	DEDUPE_FIELD_ID NUMBER(10,0),
	DEDUPE_PROCESSED_RECORD_ID NUMBER(10,0) NOT NULL,
	NEW_VAL VARCHAR2(4000),
	OLD_VAL VARCHAR2(4000),
	REFERENCE_ID NUMBER(10,0),
	TAG_GROUP_ID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_DEDUPE_MERGE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_MERGE_LOG_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_MERGE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_MERGE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MERGE_LOG_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MERGE_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_MERGE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MERGE_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_MERGE_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MERGE_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_MERGE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.forecasting_slot (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	number_of_years				NUMBER(10, 0) NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					VARCHAR2(10),
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0) NOT NULL,
	created_dtm 				DATE NOT NULL,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	include_all_inds			NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_FORECASTING			PRIMARY KEY	(APP_SID, FORECASTING_SID),
	CONSTRAINT FK_FORCSTING_SCNRIO_RUN	FOREIGN KEY	(APP_SID, SCENARIO_RUN_SID) REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID),
	CONSTRAINT FK_FORCSTING_CREATED_BY	FOREIGN KEY	(APP_SID, CREATED_BY_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_FORCSTING_RFRSHED_BY	FOREIGN KEY	(APP_SID, LAST_REFRESH_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_FORCSTING_PERIOD_INT	FOREIGN KEY	(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID) REFERENCES CSR.PERIOD_INTERVAL(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID),
	CONSTRAINT CK_FORCSTING_RULE_TYPE 	CHECK (RULE_TYPE IN ('Fixed', '*', '+')),
	CONSTRAINT CK_FORCSTING_ALL_INDS	CHECK (INCLUDE_ALL_INDS IN (0, 1))
);
CREATE TABLE csrimp.forecasting_slot (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	number_of_years				NUMBER(10, 0) NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					VARCHAR2(10),
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0) NOT NULL,
	created_dtm 				DATE NOT NULL,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	include_all_inds			NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_FORECASTING			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID),
	CONSTRAINT FK_FORECASTING_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE,
	CONSTRAINT CK_FORCSTING_RULE_TYPE 	CHECK (RULE_TYPE IN ('Fixed', '*', '+')),
	CONSTRAINT CK_FORCSTING_ALL_INDS	CHECK (INCLUDE_ALL_INDS IN (0, 1))
);
CREATE TABLE csr.forecasting_indicator (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_IND			PRIMARY KEY	(APP_SID, FORECASTING_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_IND 		FOREIGN KEY	(APP_SID, IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_FOR_SID	FOREIGN KEY	(APP_SID, FORECASTING_SID) REFERENCES CSR.FORECASTING_SLOT(APP_SID, FORECASTING_SID)
);
CREATE TABLE csrimp.forecasting_indicator (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_IND			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.forecasting_region (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_REGION		PRIMARY KEY	(APP_SID, FORECASTING_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REG_REG 		FOREIGN KEY	(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REG_FOR_SID	FOREIGN KEY	(APP_SID, FORECASTING_SID) REFERENCES CSR.FORECASTING_SLOT(APP_SID, FORECASTING_SID)
);
CREATE TABLE csrimp.forecasting_region (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_REGION			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REGION_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.forecasting_rule (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	rule_type					VARCHAR2(10) NOT NULL,
	rule_val					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_RULE				PRIMARY KEY	(app_sid, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_RULE_SLOT_SID 	FOREIGN KEY	(app_sid, forecasting_sid) REFERENCES csr.forecasting_slot(app_sid, forecasting_sid),
	CONSTRAINT FK_FORECAST_RULE_IND_SID 	FOREIGN KEY	(app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid),
	CONSTRAINT FK_FORECAST_RULE_REGION_SID 	FOREIGN KEY	(app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid),
	CONSTRAINT CK_FORECAST_RULE_RULE_TYPE 	CHECK (rule_type IN ('Fixed', '*', '+'))
);
CREATE TABLE csr.forecasting_val (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	val_number					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_VAL				PRIMARY KEY	(app_sid, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_VAL_SLOT_SID 	FOREIGN KEY	(app_sid, forecasting_sid) REFERENCES csr.forecasting_slot(app_sid, forecasting_sid),
	CONSTRAINT FK_FORECAST_VAL_IND_SID 		FOREIGN KEY	(app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid),
	CONSTRAINT FK_FORECAST_VAL_REGION_SID 	FOREIGN KEY	(app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)
);
CREATE TABLE csrimp.forecasting_rule (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	rule_type					VARCHAR2(10) NOT NULL,
	rule_val					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_RULE			PRIMARY KEY	(csrimp_session_id, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_RULE_SESSION	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.forecasting_val (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	val_number					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_VAL			PRIMARY KEY	(csrimp_session_id, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_VAL_SESSION	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csr.batched_import_type (
	batch_import_type_id	NUMBER(10) NOT NULL,
	label					VARCHAR2(255) NOT NULL,
	assembly				VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_batched_import_type PRIMARY KEY (batch_import_type_id)
);
 
CREATE TABLE csr.batch_job_batched_import (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	batch_job_id			NUMBER(10) NOT NULL,
	batch_import_type_id	NUMBER(10) NOT NULL,
	settings_xml			XMLTYPE NOT NULL,
	file_blob				BLOB,
	file_name				VARCHAR2(1024),
	error_file_blob			BLOB,
	error_file_name			VARCHAR2(1024),
	CONSTRAINT pk_bj_batched_import PRIMARY KEY (app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_import_bj_id FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job(app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_import_type FOREIGN KEY (batch_import_type_id) REFERENCES csr.batched_import_type (batch_import_type_id)  
);
CREATE TABLE CHAIN.BSCI_RSP (
	rsp_id							NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_bsci_rsp PRIMARY KEY (rsp_id)
);
COMMENT ON TABLE CHAIN.BSCI_RSP IS 'desc="RSP"';
COMMENT ON COLUMN CHAIN.BSCI_RSP.LABEL IS 'desc="Label"';
CREATE TABLE CHAIN.FILTER_EXPORT_BATCH (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10) NOT NULL,
	COMPOUND_FILTER_ID		NUMBER(10) NULL,
	CARD_GROUP_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_FILTER_EXPORT_BATCH PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_BATCH_COMPOUND_FILTER 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID)
	REFERENCES CHAIN.COMPOUND_FILTER (APP_SID, COMPOUND_FILTER_ID);
ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_CARD_GROUP 
    FOREIGN KEY (CARD_GROUP_ID)
	REFERENCES CHAIN.CARD_GROUP (CARD_GROUP_ID);


CREATE UNIQUE INDEX CHAIN.UK_DEDUPE_MERGE_LOG ON CHAIN.DEDUPE_MERGE_LOG (APP_SID, DEDUPE_PROCESSED_RECORD_ID, NVL(DEDUPE_FIELD_ID, NVL(REFERENCE_ID, TAG_GROUP_ID)));
ALTER TABLE CHAIN.DEDUPE_MERGE_LOG ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_PROCESSED
	FOREIGN KEY (APP_SID, DEDUPE_PROCESSED_RECORD_ID)
	REFERENCES CHAIN.DEDUPE_PROCESSED_RECORD (APP_SID, DEDUPE_PROCESSED_RECORD_ID);
	
ALTER TABLE CHAIN.DEDUPE_MERGE_LOG ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_FLD
	FOREIGN KEY (DEDUPE_FIELD_ID)
	REFERENCES CHAIN.DEDUPE_FIELD (DEDUPE_FIELD_ID);
	
ALTER TABLE CHAIN.DEDUPE_MERGE_LOG ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_REF
	FOREIGN KEY (APP_SID, REFERENCE_ID)
	REFERENCES CHAIN.REFERENCE (APP_SID, REFERENCE_ID);
	
ALTER TABLE chain.dedupe_processed_record ADD company_data_merged NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT chk_company_data_merged 
	CHECK (company_data_merged = 0 AND matched_to_company_sid IS NULL 
		OR company_data_merged IN (0,1) AND matched_to_company_sid IS NOT NULL
		OR company_data_merged = 1 AND created_company_sid IS NOT NULL);
ALTER TABLE csrimp.chain_dedup_proce_record ADD company_data_merged NUMBER(1, 0) NOT NULL;
ALTER TABLE chain.import_source ADD is_owned_by_system NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE chain.import_source ADD CONSTRAINT chk_is_owned_by_system CHECK (is_owned_by_system IN (0,1));
ALTER TABLE csrimp.chain_import_source ADD is_owned_by_system NUMBER(1,0) NOT NULL;
CREATE UNIQUE INDEX chain.uk_import_source_system_owned ON chain.import_source (CASE WHEN is_owned_by_system = 1 THEN app_sid END);
  
ALTER TABLE chain.TT_DEDUPE_PROCESSED_ROW ADD company_data_merged NUMBER(1,0);
create index chain.ix_dedupe_merge_log_fld on chain.dedupe_merge_log (app_sid, dedupe_field_id);
create index chain.ix_dedupe_merge_log_tg on chain.dedupe_merge_log (app_sid, tag_group_id);
create index chain.ix_dedupe_merge_log_ref on chain.dedupe_merge_log (app_sid, reference_id);
create index chain.ix_dedupe_merge_log_rec_id on chain.dedupe_merge_log (app_sid, dedupe_processed_record_id);
create index chain.ix_dedupe_processed_rec_comp on chain.dedupe_processed_record (app_sid, matched_to_company_sid);
ALTER TABLE csr.issue_type DROP CONSTRAINT CHK_IT_ACARD_VALID;
ALTER TABLE csr.issue_type ADD CONSTRAINT CHK_IT_ACARD_VALID CHECK (AUTO_CLOSE_AFTER_RESOLVE_DAYS >= 0);
ALTER TABLE csr.issue_type ADD comment_is_optional NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.issue_type ADD comment_is_optional NUMBER(1) NOT NULL;
ALTER TABLE csr.issue_log
MODIFY message NULL;
ALTER TABLE cms.cms_aggregate_type ADD (
	normalize_by_aggregate_type_id	NUMBER(10,0)
);
ALTER TABLE csrimp.cms_aggregate_type ADD (
	normalize_by_aggregate_type_id	NUMBER(10,0)
);
ALTER TABLE cms.cms_aggregate_type ADD CONSTRAINT fk_cms_agg_type_cms_agg_type
	FOREIGN KEY (app_sid, normalize_by_aggregate_type_id) REFERENCES cms.cms_aggregate_type(app_sid, cms_aggregate_type_id);
CREATE INDEX cms.ix_cms_agg_norm_by_agg_type_id ON cms.cms_aggregate_type (app_sid, normalize_by_aggregate_type_id);
DROP TYPE chain.T_FILTER_AGG_TYPE_TABLE;
CREATE OR REPLACE TYPE chain.T_FILTER_AGG_TYPE_ROW AS
	OBJECT (
		card_group_id					NUMBER(10),
		aggregate_type_id				NUMBER(10),
		description 					VARCHAR2(1023),
		format_mask						VARCHAR2(255),
		filter_page_ind_interval_id		NUMBER(10),
		accumulative					NUMBER(1),
		aggregate_group					VARCHAR2(255),
		unit_of_measure					VARCHAR2(255),
		normalize_by_aggregate_type_id	NUMBER(10)
	);
/
CREATE OR REPLACE TYPE chain.T_FILTER_AGG_TYPE_TABLE AS
	TABLE OF chain.T_FILTER_AGG_TYPE_ROW;
/

ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_START NUMBER(10,0) DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.COMPANY_TYPE ADD (
	CREATE_DOC_LIBRARY_FOLDER 		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_CREATE_DOC_LIB_FOLDER_1_0 CHECK (CREATE_DOC_LIBRARY_FOLDER IN (1, 0))
);
ALTER TABLE CSR.DOC_FOLDER ADD (
	COMPANY_SID 					NUMBER(10),
	CONSTRAINT FK_DOC_FOLDER_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
);
ALTER TABLE CSR.DOC_FOLDER ADD (
	IS_SYSTEM_MANAGED 				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_DOC_FOLDER_IS_SYS_MNGD_1_0 CHECK (IS_SYSTEM_MANAGED IN (1, 0))
);
ALTER TABLE CSRIMP.CHAIN_COMPANY_TYPE ADD (
	CREATE_DOC_LIBRARY_FOLDER		NUMBER(1)
);
UPDATE csrimp.chain_company_type SET create_doc_library_folder = 0;
ALTER TABLE csrimp.chain_company_type MODIFY create_doc_library_folder NOT NULL;
ALTER TABLE csrimp.chain_company_type ADD CONSTRAINT chk_create_doc_lib_folder_1_0 CHECK (create_doc_library_folder IN (1, 0));
ALTER TABLE CSRIMP.DOC_FOLDER ADD (
	COMPANY_SID						NUMBER(10),
	IS_SYSTEM_MANAGED				NUMBER(1)
);
UPDATE csrimp.doc_folder SET is_system_managed = 0;
ALTER TABLE csrimp.doc_folder MODIFY is_system_managed NOT NULL;
ALTER TABLE csrimp.doc_folder ADD CONSTRAINT chk_doc_folder_is_sys_mngd_1_0 CHECK (is_system_managed IN (1, 0));
CREATE INDEX csr.ix_doc_folder_company_sid ON csr.doc_folder (app_sid, company_sid);
	  
ALTER TABLE csr.ind_description
ADD last_changed_dtm DATE;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD (
	FORCE_LOGIN_AS_COMPANY			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_FORCE_LOGIN_AS_CO CHECK (FORCE_LOGIN_AS_COMPANY IN (0,1))
);
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS
ADD (
	FORCE_LOGIN_AS_COMPANY			NUMBER(1) NULL
);
ALTER TABLE csr.capability ADD description VARCHAR2(1024);
ALTER TABLE CHAIN.BSCI_AUDIT
ADD AUDIT_RESULT VARCHAR2(255) NULL;
ALTER TABLE CHAIN.BSCI_AUDIT
DROP COLUMN AUDIT_SCORE;
ALTER TABLE CHAIN.BSCI_AUDIT
DROP COLUMN AUDIT_SUCCESS;
ALTER TABLE CHAIN.BSCI_SUPPLIER
ADD (
	RSP_ID							NUMBER(10) NULL,
	IS_AUDIT_IN_PROGRESS			NUMBER(1) NULL,
	AUDIT_IN_PROGRESS_DTM			DATE NULL,
	CONSTRAINT PK_BSCI_SUPPLIER PRIMARY KEY (COMPANY_SID),
	CONSTRAINT CHK_IS_AUDIT_IN_PROGRESS CHECK(IS_AUDIT_IN_PROGRESS IN (0,1)),
	CONSTRAINT FK_BSCI_SUPPLIER_RSP FOREIGN KEY (RSP_ID)
	REFERENCES CHAIN.BSCI_RSP (RSP_ID)
);
COMMENT ON TABLE CHAIN.BSCI_SUPPLIER IS 'desc="BSCI Supplier"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.APP_SID IS 'app_sid';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.COMPANY_SID IS 'company';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ADDRESS IS 'desc="Address"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CITY IS 'desc="City"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.INDUSTRY IS 'desc="Industry"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.COUNTRY IS 'desc="Country"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.POSTCODE IS 'desc="Postcode"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.REGION IS 'desc="Region"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.TERRITORY IS 'desc="Territory"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ADDRESS_LOCATION_TYPE IS 'desc="Address location type"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.ALIAS IS 'desc="Alias"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_ANNOUNCEMENT_METHOD IS 'desc="Audit announcement method"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.FACTORY_CONTACT IS 'desc="Factory contact"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_EXPIRATION_DTM IS 'desc="Audit expiration date"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_IN_PROGRESS IS 'desc="Is audit in progress?"';	
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_RESULT IS 'desc="Audit result"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.BSCI_COMMENTS IS 'desc="BSCI comments"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.LINKED_PARTICIPANTS IS 'desc="Linked participants"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IN_COMMITMENTS IS 'desc="Commitments"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IN_SUPPLY_CHAIN IS 'desc="Supply chain"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.LEGAL_STATUS IS 'desc="Legal status"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NAME IS 'desc="Name"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NUMBER_OF_ASSOCIATES IS 'desc="Number of associates"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.NUMBER_OF_BUILDINGS IS 'desc="Number of buildings"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PARTICIPANT_NAME IS 'desc="Participant name"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PRODUCT_GROUP IS 'desc="Product group"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.PRODUCT_TYPE IS 'desc="Product type"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CODE_OF_CONDUCT_ACCEPTED IS 'desc="CoC accepted"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.CODE_OF_CONDUCT_SIGNED IS 'desc="CoC signed"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_DTM IS 'desc="Audit date"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.SECTOR IS 'desc="Sector"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.WEBSITE IS 'desc="Website"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.YEAR_FOUNDED IS 'desc="Year founded"';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.RSP_ID IS 'desc="RSP",enum,enum_desc_col=LABEL';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.IS_AUDIT_IN_PROGRESS IS 'desc="Audit in progress",boolean';
COMMENT ON COLUMN CHAIN.BSCI_SUPPLIER.AUDIT_IN_PROGRESS_DTM IS 'desc="Audit in progress date"';
ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
ADD AUDIT_RESULT VARCHAR2(255) NULL;
ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
DROP COLUMN AUDIT_SCORE;
ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
DROP COLUMN AUDIT_SUCCESS;
ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER
ADD (
	RSP_ID							NUMBER(10) NULL,
	IS_AUDIT_IN_PROGRESS			NUMBER(1) NULL,
	AUDIT_IN_PROGRESS_DTM			DATE NULL
);
ALTER TABLE CSR.BATCH_JOB
ADD REQUESTED_BY_COMPANY_SID NUMBER(10, 0);


grant select, insert, update, delete on csrimp.chain_dedupe_merge_log to tool_user;
grant select, insert, update on chain.dedupe_merge_log to csrimp;
grant select on chain.dedupe_merge_log_id_seq to csrimp;
grant select on chain.dedupe_merge_log_id_seq to CSR;
grant select, insert, update on chain.dedupe_merge_log to CSR;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_TABLE TO csr;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_ROW TO csr;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_TABLE TO cms;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_ROW TO cms;
GRANT INSERT, UPDATE ON csr.doc_folder TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.property_mandatory_roles TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_slot TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_indicator TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_region TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_rule TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_val TO csrimp;


ALTER TABLE CHAIN.DEDUPE_MERGE_LOG ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP (APP_SID, TAG_GROUP_ID);
 
ALTER TABLE CSR.BATCH_JOB ADD CONSTRAINT FK_BATCH_JOB_COMPANY 
    FOREIGN KEY (APP_SID, REQUESTED_BY_COMPANY_SID)
	REFERENCES CSR.SUPPLIER (APP_SID, COMPANY_SID);
ALTER TABLE CHAIN.FILTER_EXPORT_BATCH ADD CONSTRAINT FK_FEB_BATCH_JOB 
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB (APP_SID, BATCH_JOB_ID);

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
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, ist.enable_manual_comp_date, ist.comment_is_optional,
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
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
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
	
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_source_data sd
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
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, NULL note, NULL reference,
		NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid,
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask,
		x.auto_source
	FROM (
		-- Consumption
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.consumption val_number, NULL cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.consumption cost, m.auto_source
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;
CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

 	
UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.MeanScoresDataExporter'
 WHERE plugin_id = 14;
 
 UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.SuepMeanScoresDataExporter'
WHERE plugin_id = 15;
 	
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.import_source (app_sid, import_source_id, name, position, can_create, lookup_key, is_owned_by_system)
	SELECT app_sid, chain.dedupe_rule_id_seq.nextval, 'User interface', 0, 1, 'SystemUI', 1
	  FROM csr.customer;
END;
/
BEGIN
	security.user_pkg.logonAdmin;
	
	FOR x IN (
		SELECT sr.app_sid, sr.substance_id, sr.region_sid, s.ref 
		  FROM chem.substance_region sr
		  JOIN chem.substance s ON s.substance_id =sr.substance_id
		   AND s.app_sid = sr.app_sid
		  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_item_id 
		   AND fi.app_sid = sr.app_sid
		 WHERE (s.app_sid, s.substance_id) IN (
			SELECT app_sid, substance_id 
			  FROM chem.substance 
			 WHERE is_central=0)
		   AND (fi.app_sid, fi.current_state_id) NOT IN (
				SELECT app_sid, flow_state_id 
				  FROM csr.flow_state 
				 WHERE lookup_key='APPROVAL_NOT_REQUIRED')
		   AND local_ref IS NULL)
	LOOP
		UPDATE chem.substance_region
		   SET local_ref = x.ref
		 WHERE substance_id = x.substance_id
		   AND region_sid = x.region_sid
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
/* Already exists
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Enable Dataview Bar Variance Options', 0);
*/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (26, 'Add missing company folders in chain document library', 'Creates any missing company folders in the chain document library if the "Create document library folder" setting is set on the company type.', 'AddMissingCompanyDocFolders', NULL);
DECLARE
	v_id    NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRForecasting', 'csr.forecasting_pkg', null, v_id);
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
	NULL;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 4
	 WHERE measure_conversion = 'tonnes (metric)';
	
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 32,
	       measure_conversion = 'MMBTU'
	 WHERE higg_question_option_id = 2852; /* MMBTU (UK) */
	 
	UPDATE chain.higg_question_option
	   SET std_measure_conversion_id = 50,
	       measure_conversion = 'TJ'
	 WHERE higg_question_option_id = 2855; /* TJ */
END;
/
BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Import core translations', 0);
	
	INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (11, 'Indicator translations', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorTranslationExporter');
	
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (0, 'Indicator translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (1, 'Region translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.RegionTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_IMPORT_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (2, 'Delegation translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.DelegationTranslationImporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
	VALUES (29, 'Batched importer', null, 'batch-importer', 0, null);
END;
/
 
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name        => 'csr.BATCHEDIMPORTSCLEARUP',
		job_type        => 'PLSQL_BLOCK',
		job_action      => 'BEGIN security.user_pkg.logonadmin(); csr.batch_importer_pkg.ScheduledFileClearUp; commit; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Schedule for removing batched imports file data from the database, so we do not use endless space'
	);
END;
/
BEGIN
	UPDATE csr.capability 
	   SET description='User Management: Turns on the ability to send messages to users on user list page'
	 WHERE name = 'Message users';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of email/full name panel on User details page'

	 WHERE name = 'Edit user details';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Groups section on User details page'

	 WHERE name = 'Edit user groups';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Starting points section on User details page'

	 WHERE name = 'Edit user starting points';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Delegation cover section on User details page'

	 WHERE name = 'Edit user delegation cover';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of default User roles section on User details page'

	 WHERE name = 'Edit user roles';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of restricted User roles section on User details page (based on which roles you have ability to grant to)'

	 WHERE name = 'User roles admin';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Active checkbox on User details page'

	 WHERE name = 'Edit user active';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Accessibility section on User details page'

	 WHERE name = 'Edit user accessibility';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Send alerts? checkbox on User details page'

	 WHERE name = 'Edit user alerts';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Regional settings (language / culture) on User details page'

	 WHERE name = 'Edit user regional settings';
	UPDATE csr.capability

	   SET description='User Management: Allows editing of Regions with which user is associated section on User details page (Note: This field is not necessary on most new sites. It is only used with the Community involvement module.)'

	 WHERE name = 'Edit user region association';
	UPDATE csr.capability

	   SET description='Delegations: Allows a user to copy forward values from the previous sheet'

	 WHERE name = 'Copy forward delegation';
	UPDATE csr.capability

	   SET description='Reporting: Allows user to save region sets for other users to access'

	 WHERE name = 'Save shared region sets';
	UPDATE csr.capability

	   SET description='Reporting: Allows user to save indicator sets for other users to access'

	 WHERE name = 'Save shared indicator sets';
	UPDATE csr.capability

	   SET description='User Management: Allows the display of the user fields user name, full name, friendly name, email, job title and phone number in user management'

	 WHERE name = 'View user details';
	UPDATE csr.capability

	   SET description='Delegations: It''s possible in delegations to submit a parent before a child (e.g. if the person who normally enters is off on holiday). Turning this on stops this happening.'

	 WHERE name = 'Allow parent sheet submission before child sheet approval';
	UPDATE csr.capability

	   SET description='Delegations: Allows a sheet to be returned once approved'

	 WHERE name = 'Allow sheet to be returned once approved';
	UPDATE csr.capability

	   SET description='Delegations: Only allow bottom delegation to enter data'

	 WHERE name = 'Only allow bottom delegation to enter data';
	UPDATE csr.capability

	   SET description='Data Explorer: Shows the Suppress unmerged data message checkbox'

	 WHERE name = 'Highlight unmerged data';
	UPDATE csr.capability

	   SET description='Region Management: Show/hide ability to link documents to regions (used for CRC reporting but could be implemented more broadly)'

	 WHERE name = 'Edit Region Docs';
	UPDATE csr.capability

	   SET description='Templated Reports: Needed to manage advanced settings for administering templated reports e.g. "change owner"'

	 WHERE name = 'Manage all templated report settings';
	UPDATE csr.capability

	   SET description='Delegations: Allows a user to subdelegate sheets'

	 WHERE name = 'Subdelegation';
	UPDATE csr.capability

	   SET description='Delegations: Allows a user to split a delegation into separate child regions'

	 WHERE name = 'Split delegations';
	UPDATE csr.capability

	   SET description='Delegations: Allows the user to raise a data change request for a sheet they have already submitted'

	 WHERE name = 'Allow users to raise data change requests';
	UPDATE csr.capability

	   SET description='My Details: Allows user to change their full name and email address'

	 WHERE name = 'Edit personal details';
	UPDATE csr.capability

	   SET description='Data Explorer: On-the-fly calculations are often used in Data Explorer to show this year versus the previous year. In this situation, showing the previous year label doesn''t really make sense, so this capability can be used to hide it.'

	 WHERE name = 'Hide year on chart axis labels when chart has FlyCalc';
	UPDATE csr.capability

	   SET description='My Details: Show and change who is covering for you on delegation data provision'

	 WHERE name = 'Edit personal delegation cover';
	UPDATE csr.capability

	   SET description='Delegations: Show additional export option in sheet export toolbar item dropdown'

	 WHERE name = 'Can export delegation summary';
	UPDATE csr.capability

	   SET description='System Management: This capability is required to view the audit log on the Indicator details, Region details, and User details pages'

	 WHERE name = 'View user audit log';
	UPDATE csr.capability

	   SET description='Delegations: Shows a link to the delegation from the Sheet page'

	 WHERE name = 'View Delegation link from Sheet';
	UPDATE csr.capability

	   SET description='Delegations: Shows a message indicating there are unsaved values on a delegation form when you click away from the web page'

	 WHERE name = 'Enable Delegation Sheet changes warning';
	UPDATE csr.capability

	   SET description='Portals: Tabs (or Portal pages) can generally only be edited by the owner. This capability allows users to make changes to any tab (including adding items, editing tab settings, deleting the tab, hiding the tab or showing tabs that they have hidden) via the Options menu on their homepage.'

	 WHERE name = 'Manage any portal';
	UPDATE csr.capability

	   SET description='CMS: Allows users to see Public filters folder in list views (ability to write to the folder is permission controlled)'

	 WHERE name = 'Allow user to share CMS filters';
	UPDATE csr.capability

	   SET description='Portals: Allows user to add new portal tabs. Also allows a user to copy a tab, hide a tab or view tabs they have hidden via the Options menu on their homepage.'

	 WHERE name = 'Add portal tabs';
	UPDATE csr.capability

	   SET description='User Management: Show / edit line-manager field in the User details page'

	 WHERE name = 'Edit user line manager';
	UPDATE csr.capability

	   SET description='Excel Models: Treat N/A as a blank cell value in Excel models instead of as N/A'

	 WHERE name = 'Suppress N\A''s in model runs';
	UPDATE csr.capability

	   SET description='Templated Reports: View and download any templated reports, even if you didn''t generate or receive them'

	 WHERE name = 'Download all templated reports';
	UPDATE csr.capability

	   SET description='Delegations: Data Change requests where the user''s data has been approved normally need the current owner to approve them. If enabled, the form is automatically returned to the user.'

	 WHERE name = 'Automatically approve Data Change Requests';
	UPDATE csr.capability

	   SET description='Delegations: Allows users to change values on delegations sheets in spite of system lock date settings'

	 WHERE name = 'Can edit forms before system lock date';
	UPDATE csr.capability

	   SET description='User Management: Allows management of group membership from the users list page'

	 WHERE name = 'Can manage group membership list page';
	UPDATE csr.capability
	   SET description='User Management: Allows deactivation of users from the users list page'
	 WHERE name = 'Can deactivate users list page';
	UPDATE csr.capability
	   SET description='System Management: Allows user to view emission factors'
	 WHERE name = 'View emission factors';
	UPDATE csr.capability
	   SET description='System Management: Allows user to edit emission factors'
	 WHERE name = 'Manage emission factors';
END;
/
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 121, 'Capability enabled');
BEGIN
	DELETE FROM csr.capability
	 where name = 'Use gauge-style charts';
	UPDATE csr.capability 
	   SET description='User Management: Turns on the ability to send messages to users on user list page'
	 WHERE name = 'Message users';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of email/full name panel on User details page'
	 WHERE name = 'Edit user details';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Groups�section on User details page'
	 WHERE name = 'Edit user groups';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Starting points�section on User details page'
	 WHERE name = 'Edit user starting points';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Delegation cover section on User details page'
	 WHERE name = 'Edit user delegation cover';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of default�User roles section on User details page'
	 WHERE name = 'Edit user roles';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of restricted User roles�section on User details�page (based on which roles you have ability to grant to)'
	 WHERE name = 'User roles admin';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Active checkbox on User details page'
	 WHERE name = 'Edit user active';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Accessibility section on User details page'
	 WHERE name = 'Edit user accessibility';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Send alerts? checkbox on User details page'
	 WHERE name = 'Edit user alerts';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Regional settings (language / culture) on User details page'
	 WHERE name = 'Edit user regional settings';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Regions with which user is associated section on User details page (Note: This field is not necessary on most new sites. It is only used with the Community involvement module.)'
	 WHERE name = 'Edit user region association';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to copy forward values from the previous sheet'
	 WHERE name = 'Copy forward delegation';
	UPDATE csr.capability
	   SET description='Reporting: Allows user to save region sets for other users to access'
	 WHERE name = 'Save shared region sets';
	UPDATE csr.capability
	   SET description='Reporting: Allows user to save indicator sets for other users to access'
	 WHERE name = 'Save shared indicator sets';
	UPDATE csr.capability
	   SET description='User Management: Allows the display of the user fields user name, full name, friendly name, email, job title and phone number in user management'
	 WHERE name = 'View user details';
	UPDATE csr.capability
	   SET description='Delegations: It''s possible in delegations to submit a parent before a child (e.g. if the person who normally enters is off on holiday). Turning this on stops this happening.'
	 WHERE name = 'Allow parent sheet submission before child sheet approval';
	UPDATE csr.capability
	   SET description='Delegations: Allows a sheet to be returned once approved'
	 WHERE name = 'Allow sheet to be returned once approved';
	UPDATE csr.capability
	   SET description='Delegations: Only allow bottom delegation to enter data'
	 WHERE name = 'Only allow bottom delegation to enter data';
	UPDATE csr.capability
	   SET description='Data Explorer: Shows the�Suppress unmerged data message�checkbox'
	 WHERE name = 'Highlight unmerged data';
	UPDATE csr.capability
	   SET description='Region Management: Show/hide ability to link documents to regions (used for CRC reporting but could be implemented more broadly)'
	 WHERE name = 'Edit Region Docs';
	UPDATE csr.capability
	   SET description='Templated Reports: Needed to manage advanced settings for administering templated reports e.g. "change owner"'
	 WHERE name = 'Manage all templated report settings';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to subdelegate sheets'
	 WHERE name = 'Subdelegation';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to split a delegation into separate child regions'
	 WHERE name = 'Split delegations';
	UPDATE csr.capability
	   SET description='Delegations: Allows the user to raise a data change request for a sheet they have already submitted'
	 WHERE name = 'Allow users to raise data change requests';
	UPDATE csr.capability
	   SET description='My Details: Allows user to change their full name and email address'
	 WHERE name = 'Edit personal details';
	UPDATE csr.capability
	   SET description='Data Explorer: On-the-fly calculations are often used in Data Explorer to show this year versus the�previous year. In this situation,�showing the previous year label doesn''t really make sense, so this capability can be used to hide it.'
	 WHERE name = 'Hide year on chart axis labels when chart has FlyCalc';
	UPDATE csr.capability
	   SET description='My Details: Show and change who is covering for you on delegation data provision'
	 WHERE name = 'Edit personal delegation cover';
	UPDATE csr.capability
	   SET description='Delegations: Show additional export option in sheet export toolbar item dropdown'
	 WHERE name = 'Can export delegation summary';
	UPDATE csr.capability
	   SET description='System Management: This capability is required to view the audit log on the Indicator details, Region details, and User details pages'
	 WHERE name = 'View user audit log';
	UPDATE csr.capability
	   SET description='Delegations: Shows a�link to the delegation from the Sheet page'
	 WHERE name = 'View Delegation link from Sheet';
	UPDATE csr.capability
	   SET description='Delegations: Shows a message indicating there are unsaved values on a delegation form when you click away from the web page'
	 WHERE name = 'Enable Delegation Sheet changes warning';
	UPDATE csr.capability
	   SET description='Portals: Tabs (or Portal pages)�can generally only be edited by the owner. This capability allows users to make changes to any tab (including�adding items, editing tab settings,�deleting the tab, hiding the�tab or showing tabs that they have hidden)�via�the�Options�menu on their homepage.'
	 WHERE name = 'Manage any portal';
	UPDATE csr.capability
	   SET description='CMS: Allows users to see Public filters folder in list views (ability to write to the folder is permission controlled)'
	 WHERE name = 'Allow user to share CMS filters';
	UPDATE csr.capability
	   SET description='Portals: Allows user to add new portal tabs. �Also allows a user to copy a tab, hide a tab or view tabs they have�hidden via the Options�menu on their homepage.'
	 WHERE name = 'Add portal tabs';
	UPDATE csr.capability
	   SET description='User Management: Show / edit line-manager field in the User details page'
	 WHERE name = 'Edit user line manager';
	UPDATE csr.capability
	   SET description='Excel Models: Treat N/A as a blank cell value in Excel models instead of as N/A'
	 WHERE name = 'Suppress N\A''s in model runs';
	UPDATE csr.capability
	   SET description='Templated Reports: View and download any templated reports, even if you didn�t generate or receive them'
	 WHERE name = 'Download all templated reports';
	UPDATE csr.capability
	   SET description='Delegations: Data Change requests where the user''s data has been approved normally need the current owner to approve them. If enabled, the form is automatically returned to the user.'
	 WHERE name = 'Automatically approve Data Change Requests';
	UPDATE csr.capability
	   SET description='Delegations: Allows users to change values on delegations sheets in spite of system lock date settings'
	 WHERE name = 'Can edit forms before system lock date';
	UPDATE csr.capability
	   SET description='User Management: Allows management of group membership from the users list page'
	 WHERE name = 'Can manage group membership list page';
	UPDATE csr.capability
	   SET description='User Management: Allows deactivation of users from the users list page'
	 WHERE name = 'Can deactivate users list page';
	UPDATE csr.capability
	   SET description='System Management: Allows user to view emission factors'
	 WHERE name = 'View emission factors';
	UPDATE csr.capability
	   SET description='System Management: Allows user to edit emission factors'
	 WHERE name = 'Manage emission factors';
END;
/
DECLARE
	v_bsci_09_audit_type_id 		security.security_pkg.T_SID_ID;
	v_bsci_14_audit_type_id 		security.security_pkg.T_SID_ID;
	v_score_type_id					csr.score_type.score_type_id%TYPE;
	PROCEDURE AddClosureType(
		in_audit_type_id			csr.internal_audit_type.internal_audit_type_id%TYPE,
		in_label					VARCHAR2,
		in_lookup					VARCHAR2
	) AS
		v_audit_closure_type_id			csr.audit_closure_type.audit_closure_type_id%TYPE;
	BEGIN
		BEGIN
			INSERT INTO csr.audit_closure_type (app_sid, audit_closure_type_id, label, is_failure, lookup_key)
			VALUES (security.security_pkg.GetApp, csr.audit_closure_type_id_seq.NEXTVAL, in_label, 0, in_lookup)
			RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
		EXCEPTION
			WHEN dup_val_on_index THEN
				SELECT audit_closure_type_id
				  INTO v_audit_closure_type_id
				  FROM csr.audit_closure_type
				 WHERE app_sid = security.security_pkg.GetApp
				   AND lookup_key = in_lookup;
		END;
		
		BEGIN
			INSERT INTO csr.audit_type_closure_type (app_sid, internal_audit_type_id, audit_closure_type_id, re_audit_due_after, 
					re_audit_due_after_type, reminder_offset_days, reportable_for_months, ind_sid)
			VALUES (security.security_pkg.GetApp, in_audit_type_id, v_audit_closure_type_id, NULL, NULL, NULL, NULL, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN NULL;
		END;
	END;
	PROCEDURE DeleteScoreType(
		in_score_type_id	IN	csr.score_type.score_type_id%TYPE
	)
	AS
	BEGIN
		DELETE FROM csr.current_supplier_score
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		
		DELETE FROM csr.supplier_score_log
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		 
		DELETE FROM csr.score_threshold
		 WHERE score_type_id = in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
		
		DELETE FROM csr.score_type
		 WHERE score_type_id=in_score_type_id
		   AND app_sid = security.security_pkg.GetApp;
	END;
BEGIN
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (1, 'Yes');
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (2, 'No');
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (3, 'Orphan');
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (4, 'Idle');
	
	FOR r IN (
		SELECT bo.app_sid, c.host
		  FROM chain.bsci_options bo
		  JOIN csr.customer c ON c.app_sid = bo.app_sid
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		UPDATE chain.reference
		   SET label = 'BSCI DBID'
		 WHERE lookup_key = 'BSCI_ID'
		   AND app_sid = r.app_sid;
		
		UPDATE chain.bsci_supplier s
		   SET (is_audit_in_progress, audit_in_progress_dtm) = (
			SELECT CASE WHEN UPPER(audit_in_progress) = 'NO' THEN 0 ELSE 1 END,
				CASE WHEN INSTR(audit_in_progress, '-') > 0 THEN 
					TO_DATE(TRIM(SUBSTR(audit_in_progress, INSTR(audit_in_progress, '-') + 1)), 'yyyy-mm-dd') 
				ELSE NULL END
			  FROM chain.bsci_supplier
			 WHERE company_sid = s.company_sid
		   );
		
		SELECT internal_audit_type_id
		  INTO v_bsci_09_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE app_sid = security.security_pkg.GetApp
		   AND UPPER(lookup_key) = 'BSCI_2009';
		
		AddClosureType(v_bsci_09_audit_type_id, 'Non-compliant', 'NON_COMPLIANT');
		AddClosureType(v_bsci_09_audit_type_id, 'Improvements needed', 'IMPROVEMENTS_NEEDED');
		AddClosureType(v_bsci_09_audit_type_id, 'Good', 'GOOD');
		   
		SELECT internal_audit_type_id
		  INTO v_bsci_14_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE app_sid = security.security_pkg.GetApp
		   AND UPPER(lookup_key) = 'BSCI_2014';
		   
		AddClosureType(v_bsci_14_audit_type_id, 'A', 'A');
		AddClosureType(v_bsci_14_audit_type_id, 'B', 'B');
		AddClosureType(v_bsci_14_audit_type_id, 'C', 'C');
		AddClosureType(v_bsci_14_audit_type_id, 'D', 'D');
		AddClosureType(v_bsci_14_audit_type_id, 'E', 'E');
		AddClosureType(v_bsci_14_audit_type_id, 'Zero tolerance', 'ZERO_TOLERANCE');
		
		-- Set closure types for existing audits
		UPDATE csr.internal_audit ia
		   SET ia.audit_closure_type_id = (
			SELECT ct.audit_closure_type_id
			  FROM csr.audit_closure_type ct
			  JOIN csr.score_threshold st ON UPPER(st.description) = UPPER(ct.label)
			  JOIN csr.audit_type_closure_type atct ON atct.audit_closure_type_id = ct.audit_closure_type_id
			 WHERE ia.nc_score_thrsh_id = st.score_threshold_id
			   AND atct.internal_audit_type_id = ia.internal_audit_type_id
			)
		 WHERE ia.internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id)
		   AND EXISTS (
			SELECT 1
			  FROM csr.audit_closure_type ct
			  JOIN csr.score_threshold st ON UPPER(st.description) = UPPER(ct.label)
			  JOIN csr.audit_type_closure_type atct ON atct.audit_closure_type_id = ct.audit_closure_type_id
			 WHERE ia.nc_score_thrsh_id = st.score_threshold_id
			   AND atct.internal_audit_type_id = ia.internal_audit_type_id
		   );
		
		UPDATE chain.bsci_audit ba
		   SET ba.audit_result = (
			SELECT act.lookup_key
			  FROM csr.internal_audit ia
			  JOIN csr.audit_closure_type act ON act.audit_closure_type_id = ia.audit_closure_type_id
			 WHERE ia.internal_audit_sid = ba.internal_audit_sid
		   )
		 WHERE EXISTS (
			SELECT 1
			  FROM csr.internal_audit ia
			 WHERE ia.internal_audit_sid = ba.internal_audit_sid
		 );
		
		-- Get rid of the old score type
		UPDATE csr.internal_audit
		   SET nc_score_thrsh_id = NULL, 
		       nc_score = NULL
		 WHERE internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id);
		 
		UPDATE csr.internal_audit_type
		   SET nc_score_type_id = NULL
		 WHERE internal_audit_type_id IN (v_bsci_09_audit_type_id, v_bsci_14_audit_type_id);
		
		BEGIN
			SELECT score_type_id
			  INTO v_score_type_id
			  FROM csr.score_type
			 WHERE UPPER(label) = 'BSCI AUDIT';
			
			DeleteScoreType(v_score_type_id);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
		
		DELETE FROM csr.audit_type_closure_type
		 WHERE audit_closure_type_id IN (
			SELECT audit_closure_type_id
			  FROM csr.audit_closure_type
			 WHERE lookup_key IN ('BSCI_SUCCESS', 'BSCI_FAILURE')
		 );
		
		DELETE FROM csr.audit_closure_type
		 WHERE lookup_key IN ('BSCI_SUCCESS', 'BSCI_FAILURE');
		
		security.user_pkg.Logoff(security.security_pkg.GetAct);
	END LOOP;
END;
/
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (10, 'Filter list export', 'Credit360.ExportImport.Export.Batched.Exporters.FilterListExcelExport');
UPDATE CSR.MODULE_PARAM 
   SET PARAM_HINT = 'Should the audit score synchronization be enabled? Y/N' 
 WHERE PARAM_HINT = 'Should the audit score syncronization be enabled? Y/N';
UPDATE CSR.MODULE_PARAM 
   SET PARAM_HINT = 'Date from which audits should be synchronized (yyyy-mm-dd or leave blank for full history or is not using this feature).' 
 WHERE PARAM_HINT = 'Date from which audits should be syncronized (yyyy-mm-dd or leave blank for full history or is not using this feature).';


UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_food_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_FOOD_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_packaging_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_PACKAGING_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_transport_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_TRANSPORT_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\model_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'MODEL_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\model_pd_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'MODEL_PD_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\product_info_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'PRODUCT_INFO_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\revision_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'REVISION_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\wood\part_wood_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'PART_WOOD_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_user_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'COMPANY_USER_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\course_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'COURSE_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\demo_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'DEMO_PKG';
@&ex_if
SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\ethics_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'ETHICS_PKG';
@&ex_if
UNDEFINE ex_if


create or replace package csr.forecasting_pkg as
	procedure dummy;
end;
/
create or replace package body csr.forecasting_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.forecasting_pkg to security;
grant execute on csr.forecasting_pkg to web_user;
CREATE OR REPLACE PACKAGE csr.batch_importer_pkg as end;
/
GRANT EXECUTE ON csr.batch_importer_pkg TO WEB_USER;
create or replace package csr.capability_pkg as
	procedure dummy;
end;
/
create or replace package body csr.capability_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.capability_pkg to web_user;


@..\scenario_run_snapshot_pkg
@..\audit_pkg
@..\schema_pkg
@..\supplier_pkg
@..\chain\company_dedupe_pkg
@..\issue_pkg
@@..\issue_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\dataview_pkg
@..\doc_folder_pkg
@..\chain\company_type_pkg
@..\util_script_pkg
@..\forecasting_pkg
@..\csrimp\imp_pkg
@..\enable_pkg
@..\indicator_pkg
@..\batch_job_pkg
@..\batch_importer_pkg
@..\chain\helper_pkg
@..\csr_data_pkg
@..\capability_pkg
@..\chain\bsci_pkg
@..\image_upload_portlet_pkg
@..\chain\filter_pkg


@..\scenario_run_snapshot_body
@..\audit_body
@..\supplier_body
@..\schema_body
@..\chain\company_dedupe_body
@..\chain\chain_body
@..\chain\setup_body
@..\csrimp\imp_body
@..\audit_report_body
@@..\audit_body
@..\chem\substance_body
@..\issue_body
@@..\issue_body
@@..\csrimp\imp_body
@..\comp_regulation_report_body
@..\comp_requirement_report_body
@..\initiative_report_body
@..\meter_list_body
@..\meter_report_body
@..\property_report_body
@..\user_report_body
@..\chain\filter_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body
@..\dataview_body
@..\csr_app_body
@..\doc_folder_body
@..\doc_lib_body
@..\doc_body
@..\initiative_doc_body
@..\chain\company_type_body
@..\util_script_body
@..\forecasting_body
@..\enable_body
@..\export_feed_body
@..\indicator_body
@..\batch_importer_body
@..\chain\helper_body
@..\capability_body
@..\chain\bsci_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\cms\db\menu_body
@..\..\..\aspen2\cms\db\util_body
@..\..\..\aspen2\db\fp_user_body
@..\..\..\aspen2\db\job_body
@..\..\..\aspen2\db\number_to_string
@..\..\..\aspen2\db\trash_body
@..\..\..\aspen2\db\tree_body
@..\..\..\aspen2\DynamicTables\db\fulltext_index_body
@..\..\..\aspen2\DynamicTables\db\schema_body
@..\actions\file_upload_body
@..\actions\gantt_body
@..\actions\ind_template_body
@..\actions\initiative_body
@..\actions\project_body
@..\actions\reckoner_body
@..\actions\setup_body
@..\actions\task_body
@..\aggregate_ind_body
@..\approval_dashboard_body
@..\auto_approve_body
@..\calc_body
@..\calendar_body
@..\compliance_body
@..\csr_user_body
@..\deleg_plan_body
@..\delegation_body
@..\diary_body
@..\energy_star_attr_body
@..\energy_star_body
@..\energy_star_job_body
@..\enhesa_body
@..\fileupload_body
@..\flow_body
@..\form_body
@..\geo_map_body
@..\image_upload_portlet_body
@..\img_chart_body
@..\imp_body
@..\initiative_aggr_body
@..\initiative_body
@..\initiative_export_body
@..\job_body
@..\like_for_like_body
@..\logistics_body
@..\measure_body
@..\meter_alarm_stat_body
@..\meter_body
@..\meter_monitor_body
@..\meter_patch_body
@..\model_body
@..\non_compliance_report_body
@..\pending_body
@..\portlet_body
@..\postit_body
@..\property_body
@..\quick_survey_body
@..\recurrence_pattern_body
@..\region_body
@..\region_set_body
@..\region_tree_body
@..\role_body
@..\rss_body
@..\ruleset_body
@..\scenario_body
@..\scenario_run_body
@..\section_body
@..\section_root_body
@..\section_search_body
@..\sheet_body
@..\stored_calc_datasource_body
@..\strategy_body
@..\tag_body
@..\templated_report_body
@..\training_body
@..\training_flow_helper_body
@..\tree_body
@..\unit_test_body
@..\utility_body
@..\val_body
@..\chain\capability_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\company_user_body
@..\chain\dev_body
@..\chain\flow_form_body
@..\chain\higg_body
@..\chain\higg_setup_body
@..\chain\invitation_body
@..\chain\metric_body
@..\chain\newsflash_body
@..\chain\product_body
@..\chain\purchased_component_body
@..\chain\questionnaire_body
@..\chain\report_body
@..\chain\scheduled_alert_body
@..\chain\type_capability_body
@..\chain\upload_body
@..\chain\validated_purch_component_body
@..\ct\admin_body
@..\ct\consumption_body
@..\ct\link_body
@..\ct\setup_body
@..\ct\util_body
@..\ct\value_chain_report_body
@..\donations\budget_body
@..\donations\fields_body
@..\donations\funding_commitment_body
@..\donations\transition_body
@..\supplier\company_body
@..\supplier\product_body
@..\supplier\questionnaire_body
@..\supplier\supplier_user_body
@..\supplier\chain\chain_company_body
@..\supplier\chain\company_user_body
@..\supplier\chain\invite_body
@..\batch_job_body

@update_tail
