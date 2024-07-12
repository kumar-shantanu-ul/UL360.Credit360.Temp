-- Please update version.sql too -- this keeps clean builds in sync
define version=3034
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE chain.dedupe_rule_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;


CREATE TABLE chain.dedupe_rule_type (
	dedupe_rule_type_id 						NUMBER(10) NOT NULL,
	description 								VARCHAR2(100) NOT NULL,
	threshold_default 							NUMBER(3) NOT NULL,
	CONSTRAINT pk_dedupe_rule_type PRIMARY KEY (dedupe_rule_type_id), 
	CONSTRAINT chk_dd_rule_type_threshold CHECK (threshold_default <=100 AND threshold_default > 0)
);

CREATE TABLE chain.dedupe_no_match_action (
	dedupe_no_match_action_id			NUMBER(10) NOT NULL,
	description 						VARCHAR2(100) NOT NULL,
	CONSTRAINT pk_dedupe_no_match_action PRIMARY KEY (dedupe_no_match_action_id)
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE_X PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE_X UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS_X FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables


ALTER TABLE chain.dedupe_rule ADD dedupe_rule_type_id NUMBER(10) DEFAULT 1 NOT NULL;
ALTER TABLE chain.dedupe_rule ADD match_threshold NUMBER(3) DEFAULT 100 NOT NULL;
-- have to add some data to put FK on
BEGIN
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (1, 'Exact match (case insensitive)', 100);
END;
/
ALTER TABLE chain.dedupe_rule ADD CONSTRAINT fk_dedupe_rule_rule_type
	FOREIGN KEY (dedupe_rule_type_id) REFERENCES chain.dedupe_rule_type (dedupe_rule_type_id);
ALTER TABLE chain.dedupe_rule MODIFY dedupe_rule_type_id DEFAULT NULL;
ALTER TABLE chain.dedupe_rule MODIFY match_threshold DEFAULT NULL;

ALTER TABLE chain.dedupe_rule ADD CONSTRAINT chk_dd_rule_threshold CHECK (match_threshold <=100 AND match_threshold > 0);

ALTER TABLE chain.dedupe_rule_set ADD dedupe_match_type_id NUMBER(10) DEFAULT 2 NOT NULL;

ALTER TABLE CHAIN.DEDUPE_RULE ADD DEDUPE_RULE_ID NUMBER(10);

BEGIN	
	security.user_pkg.logonadmin;
	UPDATE chain.dedupe_rule SET dedupe_rule_id = chain.dedupe_rule_id_seq.nextval;
END;
/
ALTER TABLE CHAIN.DEDUPE_RULE MODIFY DEDUPE_RULE_ID NOT NULL;

ALTER TABLE CHAIN.DEDUPE_RULE DROP CONSTRAINT PK_DEDUPE_RULE;
ALTER TABLE CHAIN.DEDUPE_RULE ADD CONSTRAINT PK_DEDUPE_RULE PRIMARY KEY (APP_SID, DEDUPE_RULE_ID); 

ALTER TABLE CHAIN.DEDUPE_RULE_SET ADD DESCRIPTION VARCHAR2(255);
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.dedupe_rule_set SET description = 'Rule-'||DEDUPE_RULE_SET_ID;
END;
/
ALTER TABLE CHAIN.DEDUPE_RULE_SET MODIFY DESCRIPTION NOT NULL;

-- csrimp - new columns
-- CSRIMP.CHAIN_DEDUPE_RULE_SET 
ALTER TABLE csrimp.chain_dedupe_rule_set ADD DESCRIPTION VARCHAR2(255) NOT NULL;

ALTER TABLE csrimp.chain_dedupe_rule_set ADD DEDUPE_MATCH_TYPE_ID NUMBER(10) NOT NULL;

ALTER TABLE csrimp.chain_dedupe_rule_set RENAME CONSTRAINT PK_CHAIN_DEDUPE_RULE TO PK_CHAIN_DEDUPE_RULE_SET;
ALTER TABLE csrimp.chain_dedupe_rule_set RENAME CONSTRAINT FK_CHAIN_DEDUPE_RULE_IS TO FK_CHAIN_DEDUPE_RULE_SET_IS;

--CSRIMP.CHAIN_DEDUPE_RULE
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD DEDUPE_RULE_ID NUMBER(10) NOT NULL;

ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD DEDUPE_RULE_TYPE_ID NUMBER(10) NOT NULL;

ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE ADD MATCH_THRESHOLD NUMBER(3) NOT NULL;

ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE RENAME CONSTRAINT PK_CHAIN_DEDUPE_RULE_MAPPIN TO PK_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.CHAIN_DEDUPE_RULE RENAME CONSTRAINT FK_CHAIN_DEDUPE_RULE_MAPPIN_IS TO FK_CHAIN_DEDUPE_RULE_IS;

--CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE TO PK_MAP_CHAIN_DD_RULE_SET;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE TO UK_MAP_CHAIN_DD_RULE_SET;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET RENAME CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS TO FK_MAP_CHAIN_DD_RULE_SET_IS;

--CSRIMP.MAP_CHAIN_DEDUPE_RULE
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE_X TO PK_MAP_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE_X TO UK_MAP_CHAIN_DEDUPE_RULE;
ALTER TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE RENAME CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS_X TO FK_MAP_CHAIN_DEDUPE_RULE_IS;

--
grant select on chain.dedupe_match_type to CSR;
ALTER TABLE chain.dedupe_rule_set ADD CONSTRAINT fk_dedupe_rule_set_match_type 
	FOREIGN KEY (dedupe_match_type_id) REFERENCES chain.dedupe_match_type (dedupe_match_type_id);
	
ALTER TABLE chain.dedupe_rule_set MODIFY dedupe_match_type_id DEFAULT NULL;

ALTER TABLE chain.import_source RENAME COLUMN can_create TO dedupe_no_match_action_id;
ALTER TABLE chain.import_source DROP CONSTRAINT chk_can_create;
ALTER TABLE chain.import_source MODIFY dedupe_no_match_action_id DEFAULT 1;

--csrimp stuff
ALTER TABLE csrimp.chain_import_source RENAME COLUMN can_create TO dedupe_no_match_action_id;

BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.import_source SET dedupe_no_match_action_id = 1;
END;
/

-- add rest of basedata later
BEGIN	
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (1, 'Auto create company');
END;
/

ALTER TABLE chain.import_source ADD CONSTRAINT fk_imp_source_no_match_action
	FOREIGN KEY (dedupe_no_match_action_id) REFERENCES chain.dedupe_no_match_action (dedupe_no_match_action_id);

DROP TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_DEDUPE_PROCESSED_ROW(
	DEDUPE_PROCESSED_RECORD_ID	NUMBER(10, 0) NOT NULL,
	DEDUPE_STAGING_LINK_ID		NUMBER(10, 0) NOT NULL,
	REFERENCE					VARCHAR(512) NOT NULL,
	ITERATION_NUM				NUMBER(10, 0) NOT NULL,
	BATCH_NUM					NUMBER(10, 0) NULL,
	PROCESSED_DTM				DATE NOT NULL,
	MATCHED_TO_COMPANY_SID		NUMBER(10, 0),
	DEDUPE_ACTION_TYPE_ID		NUMBER(10, 0),
	MATCHED_DTM					DATE,
	MATCHED_BY_USER_SID			NUMBER(10, 0),
	MATCHED_TO_COMPANY_NAME		VARCHAR(512),
	IMPORT_SOURCE_NAME			VARCHAR(512) NOT NULL,
	CREATED_COMPANY_SID 		NUMBER(10, 0),
	CREATED_COMPANY_NAME		VARCHAR(512),
	DATA_MERGED					NUMBER(1,0),
	CMS_RECORD_ID 				NUMBER(10, 0),
	STAGING_LINK_DESCRIPTION 	VARCHAR(512),
	IMPORTED_USER_SID 			NUMBER(10),
	IMPORTED_USER_NAME 			VARCHAR2(256),
	MERGE_STATUS				NUMBER(10),
	ERROR_MESSAGE				VARCHAR2(4000),
	FORM_LOOKUP_KEY				VARCHAR2(255),
	DEDUPE_ACTION	 			NUMBER(1)
)
ON COMMIT DELETE ROWS;

ALTER TABLE chain.dedupe_processed_record ADD (
	batch_job_id						NUMBER(10) NULL,
	merge_status_id						NUMBER(10) NULL,
	error_message						VARCHAR2(4000) NULL,
	error_detail						VARCHAR2(4000) NULL,
	CONSTRAINT chk_ddp_prc_rec_bat_job CHECK ((batch_job_id IS NULL AND merge_status_id IS NULL) OR (batch_job_id IS NOT NULL AND merge_status_id IS NOT NULL))
);


-- Only bother with merge_status_id for exp/imp - batch_job_id and error details are only
-- really relevant to the original site
ALTER TABLE csrimp.CHAIN_DEDUP_PROCE_RECORD ADD (
	merge_status_id						NUMBER(10) NULL
);

--Merged from US6979
ALTER TABLE chain.dedupe_processed_record
  ADD dedupe_action NUMBER(1);

ALTER TABLE chain.dedupe_processed_record
  ADD CONSTRAINT chk_dedupe_action CHECK (dedupe_action IN (1,2,3));

ALTER TABLE chain.dedupe_processed_record DROP CONSTRAINT fk_dedupe_process_rec_match;
ALTER TABLE chain.dedupe_processed_record RENAME COLUMN dedupe_match_type_id TO dedupe_action_type_id;
ALTER TABLE chain.dedupe_processed_record 
	ADD CONSTRAINT chk_action_type_id CHECK (dedupe_action_type_id IN (1,2)); 

ALTER TABLE csrimp.chain_dedup_proce_record ADD dedupe_action NUMBER(1);
ALTER TABLE csrimp.chain_dedup_proce_record RENAME COLUMN dedupe_match_type_id TO dedupe_action_type_id;

create index chain.ix_dedupe_rule_dedupe_rule_t on chain.dedupe_rule (dedupe_rule_type_id);
create index chain.ix_dedupe_rule_s_dedupe_match_ on chain.dedupe_rule_set (dedupe_match_type_id);
create index chain.ix_import_source_dedupe_no_mat on chain.import_source (dedupe_no_match_action_id);

-- *** Grants ***
GRANT SELECT ON chain.dedupe_rule_type TO csr;
GRANT SELECT ON chain.dedupe_rule_id_seq TO csrimp;

GRANT SELECT ON cms.v$form TO chain;


-- ** Cross schema constraints ***
ALTER TABLE chain.dedupe_processed_record
ADD CONSTRAINT fk_ddp_prc_rec_batch_job FOREIGN KEY (app_sid, batch_job_id)
	REFERENCES csr.batch_job (app_sid, batch_job_id);

create index chain.ix_dedupe_processed_rec_batch on chain.dedupe_processed_record (app_sid, batch_job_id);

ALTER INDEX chain.ix_dedupe_proces_dedupe_match_ RENAME TO ix_dedupe_proces_dedupe_actn;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
--Merged from US6979
BEGIN
	 
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (2, 'Levenshtein (distance match)', 50);

	INSERT INTO CHAIN.DEDUPE_RULE_TYPE (DEDUPE_RULE_TYPE_ID, DESCRIPTION, THRESHOLD_DEFAULT) 
		VALUES (3, 'Jaro-Winkler (distance match)', 70);
	

	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) 
		VALUES (4, 'Contains match (case insensitive)', 100);
			
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (2, 'Mark record for manual review');
		
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) 
		VALUES (3, 'Park record');
		
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp)
	VALUES (58, 'Dedupe manual merge', 'chain.company_dedupe_pkg.ProcessUserActions');
END;
/

BEGIN
	UPDATE CHAIN.DEDUPE_MATCH_TYPE SET label = 'Automatic' WHERE DEDUPE_MATCH_TYPE_ID = 1;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../chain/chain_pkg
@../chain/dedupe_admin_pkg
@../chain/company_dedupe_pkg
@../chain/dedupe_preprocess_pkg
@../schema_pkg

@../chain/chain_body
@../chain/dedupe_admin_pkg
@../chain/dedupe_admin_body
@../csrimp/imp_body
@../chain/company_body
@../chain/company_dedupe_body
@../chain/dedupe_preprocess_body
@../chain/test_chain_utils_body
@../chain/setup_body
@../schema_body
@../supplier_body

@update_tail
