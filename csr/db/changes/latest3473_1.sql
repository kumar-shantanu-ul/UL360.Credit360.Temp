-- Please update version.sql too -- this keeps clean builds in sync
define version=3473
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.application
	 MODIFY BLOCK_SA_LOGON NULL;

UPDATE csrimp.application
   SET BLOCK_SA_LOGON = null;

ALTER TABLE csrimp.application
DROP COLUMN BLOCK_SA_LOGON;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.util_script_param
 WHERE UTIL_SCRIPT_ID = 76;

DELETE FROM csr.util_script_run_log
 WHERE UTIL_SCRIPT_ID = 76;

DELETE FROM csr.util_script
 WHERE UTIL_SCRIPT_ID = 76;

-- ** New package grants **


-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg

@../util_script_body
@../schema_body
@../enable_body
@../csrimp/imp_body

@update_tail
