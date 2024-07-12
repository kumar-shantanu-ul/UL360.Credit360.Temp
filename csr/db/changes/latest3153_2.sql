-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=2
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
	UPDATE csr.flow_capability
	   SET description = 'Survey share response'
	 WHERE flow_capability_id = 1002; /* csr_data_pkg.FLOW_CAP_CAMPAIGN_SHARE */
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
