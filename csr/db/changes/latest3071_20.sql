-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=20
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
	INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
	VALUES (303, 'Automated export change', 1);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../automated_export_pkg


@../automated_export_body

@update_tail
