-- Please update version.sql too -- this keeps clean builds in sync
define version=567
@update_header

begin
	dbms_rls.drop_policy(
		object_schema   => 'CSR',
		object_name     => 'FACTOR',
		policy_name     => 'FACTOR_POLICY'
	);
end;
/

@update_tail
