-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (29, 'Migrate Emission Factor tool', '** It needs to be tested against test environments before applying Live**. It migrates old emission factor settings to the new Emission Factor Profile tool.','MigrateEmissionFactorTool','W2990');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (29, 'Profile Name', 'Profile Name', 0, 'Migrated profile');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_pkg
@../factor_body
@../factor_set_group_pkg
@../factor_set_group_body
@../util_script_pkg
@../util_script_body

@update_tail
