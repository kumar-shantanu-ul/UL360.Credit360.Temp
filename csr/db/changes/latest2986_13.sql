-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables
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

-- Alter tables
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

-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_dedupe_merge_log to tool_user;
grant select, insert, update on chain.dedupe_merge_log to csrimp;

grant select on chain.dedupe_merge_log_id_seq to csrimp;
grant select on chain.dedupe_merge_log_id_seq to CSR;

grant select, insert, update on chain.dedupe_merge_log to CSR;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.DEDUPE_MERGE_LOG ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP (APP_SID, TAG_GROUP_ID);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.import_source (app_sid, import_source_id, name, position, can_create, lookup_key, is_owned_by_system)
	SELECT app_sid, chain.dedupe_rule_id_seq.nextval, 'User interface', 0, 1, 'SystemUI', 1
	  FROM csr.customer;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../supplier_pkg
@../chain/company_dedupe_pkg

@../supplier_body
@../schema_body
@../chain/company_dedupe_body
@../chain/chain_body
@../chain/setup_body
@../csrimp/imp_body


@update_tail
