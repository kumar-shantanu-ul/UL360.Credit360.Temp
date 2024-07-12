-- Please update version.sql too -- this keeps clean builds in sync
define version=2236
@update_header

-- although not normally a good plan this only affects csrimp, not the website
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE pf_owner = 'CSRIMP' AND function IN ('SESSIONIDCHECK')
		   AND object_owner IN ('CSRIMP', 'CMS')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

@update_tail
