-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.DEDUPE_PROCESSED_RECORD_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE SEQUENCE CHAIN.DEDUPE_MATCH_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.DEDUPE_MATCH_TYPE(
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0) NOT NULL,
	LABEL						VARCHAR(32) NOT NULL,
	CONSTRAINT PK_DEDUPE_MATCH_TYPE PRIMARY KEY (DEDUPE_MATCH_TYPE_ID),
	CONSTRAINT UC_DEDUPE_MATCH_TYPE UNIQUE (LABEL)
);

CREATE TABLE CHAIN.DEDUPE_PROCESSED_RECORD(
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	IMPORT_SOURCE_ID			NUMBER(10, 0) NOT NULL,
	COMPANY_REF					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	PROCESSED_DTM				DATE DEFAULT SYSDATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	CONSTRAINT PK_DEDUPE_PROCESSED_RECORD PRIMARY KEY (APP_SID, DEDUPE_PROCESSED_RECORD_ID),
	CONSTRAINT UC_DEDUPE_PROCESSED_RECORD UNIQUE (APP_SID, IMPORT_SOURCE_ID, COMPANY_REF, ITERATION_NUM)
);

CREATE TABLE CHAIN.DEDUPE_MATCH(
	APP_SID						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_MATCH_ID				NUMBER(10, 0) NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0) NOT NULL,
	DEDUPE_RULE_ID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_DEDUPE_MATCH PRIMARY KEY (APP_SID, DEDUPE_MATCH_ID),
	CONSTRAINT UC_DEDUPE_MATCH UNIQUE (APP_SID, DEDUPE_PROCESSED_RECORD_ID, MATCHED_TO_COMPANY_SID)
);

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW(
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	IMPORT_SOURCE_ID			NUMBER(10, 0) NOT NULL,
	COMPANY_REF					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	PROCESSED_DTM				DATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_MATCH_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	MATCHED_TO_COMPANY_NAME		VARCHAR(512),
	IMPORT_SOURCE_NAME			VARCHAR(512) NOT NULL
) 
ON COMMIT DELETE ROWS; 


CREATE TABLE CSRIMP.CHAIN_DEDUP_PROCE_RECORD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID NUMBER(10,0) NOT NULL,
	COMPANY_REF VARCHAR2(512) NOT NULL,
	DEDUPE_MATCH_TYPE_ID NUMBER(10,0),
	IMPORT_SOURCE_ID NUMBER(10,0) NOT NULL,
	ITERATION_NUM NUMBER(10,0) NOT NULL,
	MATCHED_BY_USER_SID NUMBER(10,0),
	MATCHED_DTM DATE,
	MATCHED_TO_COMPANY_SID NUMBER(10,0),
	PROCESSED_DTM DATE NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUP_PROCE_RECORD PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_PROCESSED_RECORD_ID),
	CONSTRAINT FK_CHAIN_DEDUP_PROCE_RECORD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_MATCH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_MATCH_ID NUMBER(10,0) NOT NULL,
	DEDUPE_PROCESSED_RECORD_ID NUMBER(10,0) NOT NULL,
	DEDUPE_RULE_ID NUMBER(10,0) NOT NULL,
	MATCHED_TO_COMPANY_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_MATCH PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_MATCH_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_MATCH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PROC_RECO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PROC_RECO PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PROC_RECO UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PROC_RECO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MATCH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MATCH PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MATCH UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MATCH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_COMPANY
	FOREIGN KEY (APP_SID, MATCHED_TO_COMPANY_SID)
	REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_SOURCE
	FOREIGN KEY (APP_SID, IMPORT_SOURCE_ID)
	REFERENCES CHAIN.IMPORT_SOURCE(APP_SID, IMPORT_SOURCE_ID)
;

ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_MATCH
	FOREIGN KEY (DEDUPE_MATCH_TYPE_ID)
	REFERENCES CHAIN.DEDUPE_MATCH_TYPE(DEDUPE_MATCH_TYPE_ID)
;

ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_PROC_REC
	FOREIGN KEY (APP_SID, DEDUPE_PROCESSED_RECORD_ID)
	REFERENCES CHAIN.DEDUPE_PROCESSED_RECORD(APP_SID, DEDUPE_PROCESSED_RECORD_ID)
;

ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_COMPANY
	FOREIGN KEY (APP_SID, MATCHED_TO_COMPANY_SID)
	REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.DEDUPE_MATCH ADD CONSTRAINT FK_DEDUPE_MATCH_RULE
	FOREIGN KEY (APP_SID, DEDUPE_RULE_ID)
	REFERENCES CHAIN.DEDUPE_RULE(APP_SID, DEDUPE_RULE_ID)
;


ALTER TABLE chain.dedupe_mapping ADD REFERENCE_ID NUMBER(10);
ALTER TABLE chain.dedupe_mapping ADD TAG_GROUP_ID NUMBER(10);

ALTER TABLE chain.import_source ADD LOOKUP_KEY VARCHAR2(32);

ALTER TABLE chain.dedupe_field RENAME COLUMN ORACLE_TABLE TO ENTITY;
ALTER TABLE chain.dedupe_field RENAME COLUMN ORACLE_COLUMN TO FIELD;

BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE chain.dedupe_mapping dm
	   SET reference_id = (
			SELECT reference_id
			   FROM chain.reference r
			  WHERE dm.reference_lookup = r.lookup_key
	);
	
	UPDATE chain.import_source
	   SET lookup_key = SUBSTR(name, 0, 28) || import_source_id;
END;
/
ALTER TABLE chain.import_source MODIFY LOOKUP_KEY NOT NULL;
ALTER TABLE chain.import_source ADD CONSTRAINT UC_IMPORT_SOURCE_LOOKUP UNIQUE (APP_SID, LOOKUP_KEY);
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT chk_dedupe_field_or_ref;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_dedupe_field_or_ref_or_tag 
	CHECK ((dedupe_field_id IS NOT NULL AND reference_id IS NULL AND tag_group_id IS NULL) 
		OR (dedupe_field_id IS NULL AND reference_id IS NOT NULL AND tag_group_id IS NULL)
		OR (dedupe_field_id IS NULL AND reference_id IS NULL AND tag_group_id IS NOT NULL));
	
ALTER TABLE chain.dedupe_mapping DROP COLUMN REFERENCE_LOOKUP;

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_MAPPING_REFERENCE
	FOREIGN KEY (app_sid, reference_id)
	REFERENCES chain.reference (app_sid, reference_id);

	
ALTER TABLE csrimp.chain_import_source ADD LOOKUP_KEY VARCHAR2(32);
ALTER TABLE csrimp.chain_dedupe_mapping ADD TAG_GROUP_ID NUMBER (10);
ALTER TABLE csrimp.chain_dedupe_mapping ADD REFERENCE_ID NUMBER (10);

ALTER TABLE csrimp.chain_dedupe_mapping DROP COLUMN REFERENCE_LOOKUP;

CREATE OR REPLACE TYPE CHAIN.T_DATES IS TABLE OF DATE;
/

-- *** Grants ***
grant SELECT on cms.item_id_seq to chain;
grant EXECUTE on cms.tab_pkg to chain;

GRANT EXECUTE ON csr.unit_test_pkg TO chain;
GRANT EXECUTE ON csr.T_VARCHAR2_TABLE TO chain;
GRANT EXECUTE ON csr.tag_pkg TO chain;

grant select, insert, update, delete on csrimp.chain_dedup_proce_record to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_match to web_user;

grant select, insert, update on chain.dedupe_processed_record to csrimp;
grant select, insert, update on chain.dedupe_match to csrimp;

grant select on chain.dedupe_processed_record_id_seq to csrimp;
grant select on chain.dedupe_processed_record_id_seq to CSR;
grant select on chain.dedupe_match_id_seq to csrimp;
grant select on chain.dedupe_match_id_seq to CSR;

-- non csrimp grants
grant select, insert, update on chain.dedupe_processed_record to CSR;
grant select, insert, update on chain.dedupe_match to CSR;

grant select on chain.dedupe_processed_record_id_seq to CSR;
grant select on chain.dedupe_match_id_seq to CSR;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.DEDUPE_PROCESSED_RECORD ADD CONSTRAINT FK_DEDUPE_PROCESS_REC_USER
	FOREIGN KEY (APP_SID, MATCHED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_MAPPING_TAG_GROUP
	FOREIGN KEY (app_sid, tag_group_id)
	REFERENCES csr.tag_group (app_sid, tag_group_id)
;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (1, 'Auto');
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (2, 'Manual');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../chain/chain_pkg
@../chain/helper_pkg
@../chain/company_dedupe_pkg

@../schema_body
@../chain/company_dedupe_body
@../chain/helper_body
@../csrimp/imp_body

@update_tail
