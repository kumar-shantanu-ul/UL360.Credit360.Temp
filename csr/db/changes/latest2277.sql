-- Please update version.sql too -- this keeps clean builds in sync
define version=2277
@update_header

begin
	for r in (select object_name, policy_name from all_policies where object_owner='CSR' and object_name='CALC_JOB') loop
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

@../stored_calc_datasource_body

@update_tail
