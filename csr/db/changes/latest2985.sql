-- Please update version.sql too -- this keeps clean builds in sync
define version=2985
define minor_version=0
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
BEGIN
	security.user_pkg.logonadmin;

	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
		 SELECT app_sid, flow_sid, 'csr.audit_helper_pkg.ApplyAuditNCScoreToSupplier', 'Apply Audit Findings Score to Supplier'
		   FROM csr.flow f
	      WHERE f.flow_alert_class = 'audit'
		    AND NOT EXISTS (
				SELECT NULL
				  FROM csr.flow_state_trans_helper
				 WHERE app_sid = f.app_sid
				   AND flow_sid = f.flow_sid
				   AND helper_sp = 'csr.audit_helper_pkg.ApplyAuditNCScoreToSupplier'
		    );

	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
		 SELECT app_sid, flow_sid, 'csr.audit_helper_pkg.SetMatchingSupplierFlowState', 'Transition Supplier Flow Based on Lookup Key'
		   FROM csr.flow f
	      WHERE f.flow_alert_class = 'audit'
		    AND NOT EXISTS (
				SELECT NULL
				  FROM csr.flow_state_trans_helper
				 WHERE app_sid = f.app_sid
				   AND flow_sid = f.flow_sid
				   AND helper_sp = 'csr.audit_helper_pkg.SetMatchingSupplierFlowState'
		    );
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
