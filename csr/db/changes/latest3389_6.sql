-- Please update version.sql too -- this keeps clean builds in sync
define version=3389
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

INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(3001, 'disclosure', 'Disclosure response', 0 /*Specific*/, 1 /*READ*/);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../flow_pkg
@../flow_body
@../enable_body

@update_tail
