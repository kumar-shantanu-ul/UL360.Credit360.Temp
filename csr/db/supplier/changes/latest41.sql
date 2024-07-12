-- Please update version.sql too -- this keeps clean builds in sync
define version=41
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
        object_schema   => 'SUPPLIER',
        object_name     => 'ALERT_BATCH',
        policy_name     => 'ALERT_BATCH_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'ALL_COMPANY',
        policy_name     => 'ALL_COMPANY_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'ALL_PRODUCT',
        policy_name     => 'ALL_PRODUCT_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'COMPANY',
        policy_name     => 'COMPANY_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'CUSTOMER_OPTIONS',
        policy_name     => 'CUSTOMER_OPTIONS_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'CUSTOMER_PERIOD',
        policy_name     => 'CUSTOMER_PERIOD_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'PRODUCT',
        policy_name     => 'PRODUCT_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'QUESTIONNAIRE_GROUP',
        policy_name     => 'QUESTIONNAIRE_GROUP_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'SUPPLIER',
        object_name     => 'TAG_GROUP',
        policy_name     => 'TAG_GROUP_POLICY',
        function_schema => 'SUPPLIER',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail
