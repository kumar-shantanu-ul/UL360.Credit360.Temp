-- Please update version.sql too -- this keeps clean builds in sync
define version=3396
define minor_version=5
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
INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES(4001, 'disclosureassignment', 'Disclosure assignment', 0 /*Specific*/, 1 /*READ*/);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
