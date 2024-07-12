-- Please update version.sql too -- this keeps clean builds in sync
define version=590
@update_header

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
begin
	begin
	    dbms_rls.add_policy(
	        object_schema   => 'CSR',
	        object_name     => 'APPROVAL_STEP_SHEET_ALERT',
	        policy_name     => 'APPROVAL_STEP_SHEET_ALE_POLICY',
	        function_schema => 'CSR',
	        policy_function => 'appSidCheck',
	        statement_types => 'select, insert, update, delete',
	        update_check	=> true,
	        policy_type     => dbms_rls.context_sensitive );
	exception
		when policy_already_exists then
			null;
	end;
	begin
	    dbms_rls.add_policy(
	        object_schema   => 'CSR',
	        object_name     => 'SHEET_ALERT',
	        policy_name     => 'SHEET_ALERT_POLICY',
	        function_schema => 'CSR',
	        policy_function => 'appSidCheck',
	        statement_types => 'select, insert, update, delete',
	        update_check	=> true,
	        policy_type     => dbms_rls.context_sensitive );
	exception
		when policy_already_exists then
			null;
	end;
end;
/

@update_tail
