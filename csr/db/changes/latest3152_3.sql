-- Please update version.sql too -- this keeps clean builds in sync
define version=3152
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_history TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_history TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_root_regions TO tool_user;

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
