-- Please update version.sql too -- this keeps clean builds in sync
define version=2920
define minor_version=6
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
	INSERT INTO csr.sheet_action (sheet_action_id, description, colour, downstream_description) VALUES (13, 'Data being entered', 'R', 'Data being entered');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 1, 0, 0, 0, 0, 0, 1);
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 2, 1, 1, 0, 0, 1, 1);
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 3, 0, 0, 0, 0, 0, 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg
@..\csr_data_body
@..\delegation_body
@..\sheet_body

@update_tail
