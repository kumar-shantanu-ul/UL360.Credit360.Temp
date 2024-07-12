-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=15
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
	security.user_pkg.LogonAdmin;
	INSERT INTO csr.flow_inv_type_alert_class(app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT app_sid, flow_involvement_type_id, 'audit'
	  FROM csr.flow_involvement_type
	 WHERE flow_involvement_type_id = 2 /* csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY */
	   AND (app_sid, flow_involvement_type_id, 'audit') NOT IN (SELECT app_sid, flow_involvement_type_id, flow_alert_class FROM csr.flow_inv_type_alert_class);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\enable_body

@update_tail
