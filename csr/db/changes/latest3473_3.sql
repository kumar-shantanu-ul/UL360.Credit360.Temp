-- Please update version.sql too -- this keeps clean builds in sync
define version=3473
define minor_version=3
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (79, 'Enable/Disable audit calculation changes', 'When enabled, calculation changes require a reason for the change to be entered by the user.', 'SetAuditCalcChangesFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (79,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (80, 'Enable/Disable check tolerance against zero', 'When enabled, tolerance violations are triggered when a value changes from zero.', 'SetCheckToleranceAgainstZeroFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (80,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
