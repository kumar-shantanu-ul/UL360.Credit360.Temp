-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.IMPORT_SOURCE_LOCK(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	IMPORT_SOURCE_ID	NUMBER(10, 0)	NOT NULL,
	IS_LOCKED			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_IS_LOCK_IS_LOCKED CHECK (IS_LOCKED IN (0, 1)),
	CONSTRAINT PK_IMPORT_SOURCE_LOCK PRIMARY KEY (APP_SID, IMPORT_SOURCE_ID)
)
;

ALTER TABLE CHAIN.IMPORT_SOURCE_LOCK ADD CONSTRAINT FK_IS_LOCK_IMPORT_SOURCE
	FOREIGN KEY (APP_SID, IMPORT_SOURCE_ID)
	REFERENCES CHAIN.IMPORT_SOURCE (APP_SID, IMPORT_SOURCE_ID);

-- Alter tables

-- *** Grants ***
GRANT INSERT ON CHAIN.IMPORT_SOURCE_LOCK TO CSRIMP;
-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;
	INSERT INTO chain.import_source_lock (app_sid, import_source_id)
	SELECT app_sid, import_source_id
	  FROM chain.import_source
	 WHERE is_owned_by_system = 0;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_dedupe_pkg

@../chain/chain_body
@../chain/company_dedupe_body
@../chain/dedupe_admin_body
@../chain/test_chain_utils_body
@../csrimp/imp_body

@update_tail
