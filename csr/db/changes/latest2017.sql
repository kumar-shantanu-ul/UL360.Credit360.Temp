-- Please update version.sql too -- this keeps clean builds in sync
define version=2017
@update_header

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN	
	v_list := t_tabs(  
		'ISSUE_TYPE_RAG_STATUS'
	);
	FOR I IN 1 .. v_list.count 
	LOOP
		BEGIN			
		    DBMS_RLS.ADD_POLICY(
		        object_schema   => 'CSR',
		        object_name     => v_list(i),
		        policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
		        function_schema => 'CSR',
		        policy_function => 'appSidCheck',
		        statement_types => 'select, insert, update, delete',
		        update_check	=> true,
		        policy_type     => dbms_rls.context_sensitive );
		    	DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));				
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/


@update_tail