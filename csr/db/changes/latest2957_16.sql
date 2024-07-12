-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- there shouldn't be any duplicates, but there were on uitest, so delete them if found
DELETE FROM csr.module_param
 WHERE ROWID NOT IN (
	SELECT MAX(rowid)
	  FROM csr.module_param
	 GROUP BY module_id, pos);

ALTER TABLE CSR.MODULE_PARAM ADD CONSTRAINT MODULE_PARAM_UNIQUE UNIQUE (MODULE_ID, POS);

DELETE FROM csr.util_script_param
 WHERE ROWID NOT IN (
	SELECT MAX(rowid)
	  FROM csr.util_script_param
	 GROUP BY util_script_id, pos);

ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD CONSTRAINT UTIL_SCRIPT_PARAM_UNIQUE UNIQUE (UTIL_SCRIPT_ID, POS);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
