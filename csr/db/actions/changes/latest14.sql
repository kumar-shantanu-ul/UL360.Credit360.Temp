-- Please update version.sql too -- this keeps clean builds in sync
define version=14
@update_header

CREATE OR REPLACE FUNCTION appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- This is:
	--
	--    Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR not logged on (i.e. needs to be fixed);
	-- OR logged on and data is for the current application
	--
	RETURN 'app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'') or sys_context(''SECURITY'', ''APP'') is null';
END;
/

begin
	for r in (select object_name, policy_name from user_policies where function='APPSIDCHECK') loop
		dbms_rls.drop_policy(
            object_schema   => 'ACTIONS',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

begin
    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'CUSTOMER_OPTIONS',
        policy_name     => 'CUSTOMER_OPTIONS_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'PROJECT',
        policy_name     => 'PROJECT_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'ROLE',
        policy_name     => 'ROLE_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'TAG_GROUP',
        policy_name     => 'TAG_GROUP_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'TASK_PERIOD_STATUS',
        policy_name     => 'TASK_PERIOD_STATUS_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'TASK_STATUS',
        policy_name     => 'TASK_STATUS_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail
