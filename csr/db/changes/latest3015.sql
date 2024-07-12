-- Please update version.sql too -- this keeps clean builds in sync
define version=3015
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

--start of US6189_2
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_USER_ROW AS 
	OBJECT ( 
		EMAIL			VARCHAR2(256), --matches to csr.csr_user
		FULL_NAME		VARCHAR2(256),
		FIRST_NAME		VARCHAR2(256),
		LAST_NAME 		VARCHAR2(256),
		USER_NAME 		VARCHAR2(256),
		FRIENDLY_NAME	VARCHAR2(255),
		PHONE_NUM		VARCHAR2(100),
		JOB_TITLE		VARCHAR2(100),
		CREATED_DTM		DATE,
		USER_REF		VARCHAR2(255),
		ACTIVE			NUMBER(1),
		USER_SID		NUMBER(10),
		CONSTRUCTOR FUNCTION T_DEDUPE_USER_ROW
		RETURN SELF AS RESULT
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_DEDUPE_USER_ROW AS
  CONSTRUCTOR FUNCTION T_DEDUPE_USER_ROW
	RETURN SELF AS RESULT
	AS
	BEGIN
		RETURN;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_USER_TABLE AS
 TABLE OF T_DEDUPE_USER_ROW;
/
--end of US6189_2

-- Alter tables

--start of US6189_2
ALTER TABLE chain.dedupe_processed_record
ADD imported_user_sid NUMBER(10);

ALTER TABLE csrimp.chain_dedup_proce_record
ADD imported_user_sid NUMBER(10);

ALTER TABLE chain.TT_DEDUPE_PROCESSED_ROW
ADD imported_user_sid NUMBER(10);

ALTER TABLE chain.TT_DEDUPE_PROCESSED_ROW
ADD imported_user_name VARCHAR2(256);
--end of US6189_2

ALTER TABLE chain.dedupe_mapping ADD role_sid NUMBER (10,0);
ALTER TABLE csrimp.chain_dedupe_mapping ADD role_sid NUMBER (10,0);
ALTER TABLE chain.dedupe_merge_log ADD role_sid NUMBER (10,0);
ALTER TABLE csrimp.chain_dedupe_merge_log ADD role_sid NUMBER (10,0);

ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT chk_dedupe_field_one_value_set;

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_dedupe_field_one_value_set
	CHECK ((CASE WHEN dedupe_field_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN reference_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN tag_group_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN destination_col_sid IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN role_sid IS NOT NULL THEN 1 ELSE 0 END
		) = 1);

ALTER TABLE chain.dedupe_merge_log DROP CONSTRAINT chk_dedupe_merge_one_value_set;

ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT chk_dedupe_merge_one_value_set 
	CHECK ((CASE WHEN dedupe_field_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN reference_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN tag_group_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN destination_col_sid IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN role_sid IS NOT NULL THEN 1 ELSE 0 END
		) = 1);
		
DROP INDEX CHAIN.UK_DEDUPE_MERGE_LOG;
CREATE UNIQUE INDEX CHAIN.UK_DEDUPE_MERGE_LOG ON CHAIN.DEDUPE_MERGE_LOG 
	(APP_SID, DEDUPE_PROCESSED_RECORD_ID, COALESCE(DEDUPE_FIELD_ID, REFERENCE_ID, TAG_GROUP_ID, DESTINATION_COL_SID, ROLE_SID));
	
CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_ROLE AS 
	OBJECT ( 
		USER_NAME	VARCHAR2(256),
		ROLE_SID	NUMBER(10),
		IS_SET		NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_ROLE_TABLE AS
 TABLE OF T_DEDUPE_ROLE;
/


-- *** Grants ***
GRANT UPDATE ON csr.csr_user TO chain;

-- ** Cross schema constraints ***
--start of US6189_2
ALTER TABLE chain.dedupe_processed_record ADD CONSTRAINT fk_dedupe_proc_rec_user 
	FOREIGN KEY (app_sid, imported_user_sid)
	REFERENCES csr.csr_user (app_sid, csr_user_sid);
--end if US6189_2

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT fk_dedupe_mapping_role
	FOREIGN KEY (app_sid, role_sid)
	REFERENCES csr.role (app_sid, role_sid);
	
ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT fk_dedupe_log_role
	FOREIGN KEY (app_sid, role_sid)
	REFERENCES csr.role (app_sid, role_sid);

create index chain.ix_dedupe_processed_rec_usr on chain.dedupe_processed_record (app_sid, imported_user_sid);
create index chain.ix_dedupe_map_role on chain.dedupe_mapping (app_sid, role_sid);
create index chain.ix_dedupe_log_role on chain.dedupe_merge_log (app_sid, role_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (101, 'USER', 'EMAIL', 'Email');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (102, 'USER', 'FULL_NAME', 'Full name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (103, 'USER', 'FIRST_NAME', 'First Name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (104, 'USER', 'LAST_NAME', 'Last name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (105, 'USER', 'USER_NAME', 'Username');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (106, 'USER', 'FRIENDLY_NAME', 'Friendly name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (107, 'USER', 'PHONE_NUMBER', 'Phone Number');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (108, 'USER', 'JOB_TITLE', 'Job title');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (109, 'USER', 'CREATED_DTM', 'Created date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (110, 'USER', 'USER_REF', 'User reference');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (111, 'USER', 'ACTIVE', 'User is active');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../unit_test_pkg
@../chain/chain_pkg
@../chain/company_dedupe_pkg
@../chain/test_chain_utils_pkg
@../chain/company_type_pkg
@../schema_pkg

@../unit_test_body
@../chain/company_dedupe_body
@../chain/test_chain_utils_body
@../chain/company_type_body
@../chain/company_user_body
@../schema_body
@../csrimp/imp_body

@update_tail
