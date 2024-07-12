-- Please update version.sql too -- this keeps clean builds in sync
define version=1591
@update_header

-- add missing rls
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CSR',
		    object_name     => 'SECTION_ALERT',
		    policy_name     => 'SECTION_ALERT_POLICY',
		    function_schema => 'CSR',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
END;
/

@update_tail