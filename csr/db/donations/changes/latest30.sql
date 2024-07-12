-- Please update version.sql too -- this keeps clean builds in sync
define version=30
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
    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'CONSTANT',
        policy_name     => 'CONSTANT_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'CUSTOMER_DEFAULT_EXRATE',
        policy_name     => 'CUSTOMER_DEFAULT_EXRT_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'CUSTOMER_FILTER_FLAG',
        policy_name     => 'CUSTOMER_FILTER_FLAG_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'CUSTOM_FIELD',
        policy_name     => 'CUSTOM_FIELD_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'DONATION_STATUS',
        policy_name     => 'DONATION_STATUS_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'FILTER',
        policy_name     => 'FILTER_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'LETTER_TEMPLATE',
        policy_name     => 'LETTER_TEMPLATE_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'RECIPIENT',
        policy_name     => 'RECIPIENT_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'REGION_GROUP',
        policy_name     => 'REGION_GROUP_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'SCHEME',
        policy_name     => 'SCHEME_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'SCHEME_FIELD',
        policy_name     => 'SCHEME_FIELD_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'TAG_GROUP',
        policy_name     => 'TAG_GROUP_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'DONATIONS',
        object_name     => 'USER_FIELDSET',
        policy_name     => 'USER_FIELDSET_POLICY',
        function_schema => 'DONATIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail
