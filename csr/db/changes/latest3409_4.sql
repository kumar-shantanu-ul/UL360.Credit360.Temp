-- Please update version.sql too -- this keeps clean builds in sync
define version=3409
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.customer DROP COLUMN show_feedback_fab;
ALTER TABLE csrimp.customer DROP COLUMN show_feedback_fab;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- remove enabled/disabled feedback util scripts
DELETE FROM csr.util_script_run_log WHERE util_script_id IN (71, 72);
DELETE FROM csr.util_script WHERE util_script_id IN (71, 72);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\customer_pkg
@..\util_script_pkg

@..\customer_body
@..\schema_body
@..\util_script_body
@..\csrimp\imp_body

@update_tail
