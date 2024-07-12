-- Please update version.sql too -- this keeps clean builds in sync
define version=3470
define minor_version=6
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (78, 'Toggle view source to deepest sheet', 'When enabled, viewing an issue source goes the to deepest sheet in the delegation hierarchy.', 'ToggleViewSourceToDeepestSheet');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (78, 'Enable/Disable', 'Enable = 1, Disable = 0', 0, NULL);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail