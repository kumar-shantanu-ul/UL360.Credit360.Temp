@security_functions

begin
	for r in (select object_name, policy_name from user_policies where function='APPSIDCHECK' and object_name like 'GT_%') loop
		dbms_rls.drop_policy(
            object_schema   => 'SUPPLIER',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
begin

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'GT_TARGET_SCORES',
        policy_name     => 'GT_TARGET_SCORES_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
        
    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'GT_TARGET_SCORES_LOG',
        policy_name     => 'GT_TARGET_SCORES_LOG_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
EXCEPTION
    WHEN FEATURE_NOT_ENABLED THEN
        DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');        
end;
/
