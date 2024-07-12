-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- DE12022
ALTER TABLE csrimp.compliance_item
MODIFY citation VARCHAR2(4000);

-- *** Grants ***
-- Other missing grants.
grant select,insert,update,delete on csrimp.campaign to tool_user;
grant select,insert,update,delete on csrimp.campaign_region to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
