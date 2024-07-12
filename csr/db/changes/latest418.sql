-- Please update version.sql too -- this keeps clean builds in sync
define version=418
@update_header

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'STORED_CALC_JOB',
        policy_name     => 'STORED_CALC_JOB_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

@update_tail
