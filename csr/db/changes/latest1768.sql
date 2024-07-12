-- Please update version.sql too -- this keeps clean builds in sync
define version=1768
@update_header

-- RLS
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CHAIN',
		    object_name     => 'REFERENCE',
		    policy_name     => 'REFERENCE_POLICY',
		    function_schema => 'CHAIN',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
	BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'COMPANY_REFERENCE',
		policy_name     => 'COMPANY_REFERENCE_POLICY',
		function_schema => 'CHAIN',
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