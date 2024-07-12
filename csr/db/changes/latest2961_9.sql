-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=9
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
	INSERT INTO csr.audit_type (
		audit_type_group_id, audit_type_id, label
	) VALUES (
		1, 27, 'Batch logon'
	);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO csr.logon_type (
		logon_type_id, label
	) VALUES (
		5, 'Batch'
	);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\..\..\security\db\oracle\security_pkg
@..\..\..\security\db\oracle\security_body
@..\..\..\security\db\oracle\user_pkg
@..\..\..\security\db\oracle\user_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\csr_data_pkg
@..\csr_data_body
@..\csr_user_pkg
@..\csr_user_body

@update_tail
