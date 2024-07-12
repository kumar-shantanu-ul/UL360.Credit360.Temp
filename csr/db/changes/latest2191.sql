-- Please update version.sql too -- this keeps clean builds in sync
define version=2191
@update_header

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'INVITATION_QNR_TYPE_COMPONENT'
	);
	for i in 1 .. v_list.count loop
		begin
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26) || '_POL', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.static);
			exit;
		exception
			when policy_already_exists then
				NULL;
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
				exit;
		end;
	end loop;
end;
/

@update_tail