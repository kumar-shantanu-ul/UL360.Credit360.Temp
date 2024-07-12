-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***

-- RLS

-- Data

--Only test recods exist where the application type was removed, so deleting these is safe.

DELETE FROM csr.compl_permit_application_pause cpap
 WHERE permit_application_id
	IN (SELECT permit_application_id FROM csr.compliance_permit_application cpa
		 WHERE application_type_id
		   NOT IN (SELECT application_type_id FROM csr.compliance_application_type WHERE app_sid = cpa.app_sid)
		   AND app_sid = cpap.app_sid);

DELETE FROM csr.compliance_permit_application cpa
 WHERE application_type_id
   NOT IN (SELECT application_type_id FROM csr.compliance_application_type WHERE app_sid = cpa.app_sid);

-- Alter tables
ALTER TABLE csr.compliance_permit_application ADD CONSTRAINT fk_compl_permit_app_type_id
	FOREIGN KEY (app_sid, application_type_id)
	REFERENCES csr.compliance_application_type (app_sid, application_type_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
