-- Please update version.sql too -- this keeps clean builds in sync
define version=1473
@update_header

ALTER TABLE CSR.REGION_METRIC MODIFY (
	LOOKUP_KEY		VARCHAR2(256)	NULL
);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'REGION_METRIC',
		policy_name     => 'REGION_METRIC_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'REGION_METRIC_VAL',
		policy_name     => 'REGION_METRIC_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'REGION_TYPE_METRIC',
		policy_name     => 'REGION_TYPE_METRIC_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../region_metric_pkg
@../region_metric_body

@update_tail
