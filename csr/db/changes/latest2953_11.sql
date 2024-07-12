-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=11
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (18,'Sync Delegation Plan Names','Updates names and descriptions of children delegations to match master delegation','SyncDelegPlanNames',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (18, 'Master Delegation SID','SID of the master delegation to update the children of',0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
