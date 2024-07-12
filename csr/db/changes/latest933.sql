-- Please update version.sql too -- this keeps clean builds in sync
define version=933
@update_header

BEGIN
	DELETE FROM CSR.USER_SETTING_ENTRY WHERE CATEGORY = 'CREDIT360.PORTLETS.ISSUE2' AND SETTING IN ('unassigned', 'myDepartments', 'myAssigned');
	DELETE FROM CSR.USER_SETTING WHERE CATEGORY = 'CREDIT360.PORTLETS.ISSUE2' AND SETTING IN ('unassigned', 'myDepartments', 'myAssigned');
END;
/

@..\issue_pkg
@..\issue_body

@update_tail
