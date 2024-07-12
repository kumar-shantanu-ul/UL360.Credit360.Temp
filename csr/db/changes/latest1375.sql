-- Please update version.sql too -- this keeps clean builds in sync
define version=1375
@update_header

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'METER_READING_PERIOD',
		policy_name     => 'METER_READING_PERIOD_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/
@update_tail