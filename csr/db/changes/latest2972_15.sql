-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (23,'Create custom delegation layout','Creates delegation layout and assigns it to given delegation sid','CreateCustomDelegLayout','W1698');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (23, 'Delegation SID','SID of the delegation to set layout to',0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
