-- Please update version.sql too -- this keeps clean builds in sync
define version=211
@update_header

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DEFAULT_RSS_FEED',
        policy_name     => 'DEFAULT_RSS_FEED_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'RSS_FEED',
        policy_name     => 'RSS_FEED_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail

