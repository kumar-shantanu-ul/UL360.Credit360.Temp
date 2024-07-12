-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_AUDIT_ABILITY AS
	OBJECT (
		FLOW_CAPABILITY_ID  NUMBER(10),
		PERMISSION_SET		NUMBER(10) 
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_ABILITY_TABLE AS
	TABLE OF CSR.T_AUDIT_ABILITY;
/

CREATE OR REPLACE TYPE CSR.T_AUDIT_MIGRATED_GROUP AS
	OBJECT (
		ORIGINAL_SID  	NUMBER(10),
		NEW_GROUP_SID	NUMBER(10) 
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_MIGRATED_GROUP_MAP AS
	TABLE OF CSR.T_AUDIT_MIGRATED_GROUP;
/
-- Don't think we need a csrimp table for this
CREATE TABLE CSR.MIGRATED_AUDIT (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	INTERNAL_AUDIT_SID		NUMBER(10) NOT NULL,
	MIGRATED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_MIGRATED_AUDIT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID),
	CONSTRAINT FK_MIG_AUDIT_INT_AUDIT FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
	REFERENCES CSR.INTERNAL_AUDIT (APP_SID, INTERNAL_AUDIT_SID) ON DELETE CASCADE
);



-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (59, 'Migrate non-WF audits', 
  'Migrate non-WF audits to a Workflow. Migration will fail if the site doesn''t pass the validation (see "Validate audit workflow migration" util script). Use "force migration" to skip the validation', 'MigrateAudits', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (59, 'Force (skips validation)', 'Force = 1, Don''t force = 0', 1, 0);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\audit_pkg
@..\audit_migration_pkg
@..\util_script_pkg

@..\audit_body
@..\audit_migration_body
@..\util_script_body

@update_tail
