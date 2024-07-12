-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=5
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
	INSERT INTO csr.source_type (source_type_id, description, helper_pkg, audit_url)
	VALUES (17, 'Approval dashboard', null, null);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../approval_dashboard_pkg

@../approval_dashboard_body

@update_tail
