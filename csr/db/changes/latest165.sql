-- Please update version.sql too -- this keeps clean builds in sync
define version=165
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

/*
spool rls
select '    dbms_rls.add_policy('||chr(10)||
	   '        object_schema   => '''||owner||''','||chr(10)||
	   '        object_name     => '''||table_name||''','||chr(10)||
	   '        policy_name     => '''||table_name||'_POLICY'','||chr(10)||
	   '        function_schema => '''||owner||''','||chr(10)||
	   '        policy_function => ''appSidCheck'','||chr(10)||
	   '        statement_types => ''select, insert, update, delete'','||chr(10)||
	   '        policy_type     => dbms_rls.static );'||chr(10) sql
  from all_tab_columns
 where owner = 'CSR' and column_name = 'APP_SID' and (owner, table_name) not in (select owner, view_name from all_views);
spool off
*/

begin
	for r in (select object_name, policy_name from user_policies where function='APPSIDCHECK') loop
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ACCURACY_TYPE',
        policy_name     => 'ACCURACY_TYPE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ALERT',
        policy_name     => 'ALERT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ALERT_TEMPLATE',
        policy_name     => 'ALERT_TEMPLATE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'APPROVAL_STEP_TEMPLATE',
        policy_name     => 'APPROVAL_STEP_TEMPLATE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'AUDIT_LOG',
        policy_name     => 'AUDIT_LOG_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'AUTOCREATE_USER',
        policy_name     => 'AUTOCREATE_USER_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'CSR_USER',
        policy_name     => 'CSR_USER_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'CUSTOMER',
        policy_name     => 'CUSTOMER_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'CUSTOMER_ALERT_TYPE',
        policy_name     => 'CUSTOMER_ALERT_TYPE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'CUSTOMER_HELP_LANG',
        policy_name     => 'CUSTOMER_HELP_LANG_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'CUSTOMER_PORTLET',
        policy_name     => 'CUSTOMER_PORTLET_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DELEGATION',
        policy_name     => 'DELEGATION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DELIVERABLE',
        policy_name     => 'DELIVERABLE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DIARY_EVENT',
        policy_name     => 'DIARY_EVENT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DOC_LIBRARY',
        policy_name     => 'DOC_LIBRARY_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ERROR_LOG',
        policy_name     => 'ERROR_LOG_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FEED',
        policy_name     => 'FEED_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'FORM',
        policy_name     => 'FORM_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'IMP_IND',
        policy_name     => 'IMP_IND_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'IMP_MEASURE',
        policy_name     => 'IMP_MEASURE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'IMP_REGION',
        policy_name     => 'IMP_REGION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'IMP_SESSION',
        policy_name     => 'IMP_SESSION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'IND',
        policy_name     => 'IND_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ISSUE_LOG_ALERT_BATCH',
        policy_name     => 'ISSUE_LOG_ALERT_BATCH_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ISSUE_LOG_ALERT_BATCH_RUN',
        policy_name     => 'ISSUE_LOG_ALERT_BAT_RUN_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MEASURE',
        policy_name     => 'MEASURE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'PENDING_DATASET',
        policy_name     => 'PENDING_DATASET_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'REGION',
        policy_name     => 'REGION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'REGION_RECALC_JOB',
        policy_name     => 'REGION_RECALC_JOB_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'REGION_TREE',
        policy_name     => 'REGION_TREE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'REPORTING_PERIOD',
        policy_name     => 'REPORTING_PERIOD_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ROLE',
        policy_name     => 'ROLE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SECTION',
        policy_name     => 'SECTION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SECTION_MODULE',
        policy_name     => 'SECTION_MODULE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'STORED_CALC_JOB',
        policy_name     => 'STORED_CALC_JOB_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SURVEY',
        policy_name     => 'SURVEY_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'TAB',
        policy_name     => 'TAB_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'TAG_GROUP',
        policy_name     => 'TAG_GROUP_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );

    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'TEMPLATE',
        policy_name     => 'TEMPLATE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        policy_type     => dbms_rls.static );
end;
/

@update_tail
