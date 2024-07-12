@@security_functions

BEGIN
	FOR r IN (SELECT object_name, policy_name FROM all_policies WHERE object_owner='SUPPLIER' AND function='APPSIDCHECK') LOOP
		dbms_rls.drop_policy(
            object_schema   => 'SUPPLIER',
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
 		SELECT owner, table_name, 
				trim(reverse(rpad(reverse(table_name), 26)))||'_POL' table_name_max
 		  FROM all_tab_columns 
 		 WHERE owner = 'SUPPLIER'
 		   AND column_name = 'APP_SID'
 	)
 	LOOP
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.table_name_max, 
			function_schema => r.owner,
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );

	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/


