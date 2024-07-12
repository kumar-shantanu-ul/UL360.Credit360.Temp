-- Please update version.sql too -- this keeps clean builds in sync
define version=3179
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
BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1003 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_ACTIONS */, 'campaign', 'Survey actions', 0 /*Specific*/, 1 /*security_pkg.PERMISSION_READ*/);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg

@update_tail