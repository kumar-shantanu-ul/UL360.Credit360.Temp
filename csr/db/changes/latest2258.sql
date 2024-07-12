-- Please update version.sql too -- this keeps clean builds in sync
define version=2258
@update_header

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'PLUGIN_LOOKUP',
		policy_name     => 'PLUGIN_LOOKUP_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SECTION_PLUGIN_LOOKUP',
		policy_name     => 'SECTION_PLUGIN_LOOKUP_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@update_tail
