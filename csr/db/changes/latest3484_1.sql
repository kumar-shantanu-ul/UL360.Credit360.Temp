-- Please update version.sql too -- this keeps clean builds in sync
define version=3484
define minor_version=1
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
		VALUES(3002, 'disclosure', 'Create/Cancel assignments', 1, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csr_data_pkg

@update_tail
