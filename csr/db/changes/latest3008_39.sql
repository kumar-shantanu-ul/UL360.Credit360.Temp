-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=39
@update_header

-- *** DDL ***
-- Create tables

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

-- Alter tables
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

--csrimp
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

-- *** Grants ***
-- non csrimp grants
grant select, insert, update on chain.dedupe_staging_link to CSR;

grant select on chain.dedupe_staging_link_id_seq to CSR;

-- ** Cross schema constraints ***
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

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../schema_pkg
@../chain/company_dedupe_pkg
@../chain/test_chain_utils_pkg

@../../../aspen2/cms/db/tab_body
@../schema_body
@../chain/company_dedupe_body
@../chain/test_chain_utils_body
@../csrimp/imp_body

@update_tail
