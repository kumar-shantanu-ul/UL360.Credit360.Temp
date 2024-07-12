-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
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

BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1002 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_SHARE */, 'campaign', 'Share response', 1, 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
--@../surveys/survey_body

@update_tail
