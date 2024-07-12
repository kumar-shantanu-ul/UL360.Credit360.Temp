-- Please update version.sql too -- this keeps clean builds in sync
define version=1317
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='FLOW_STATE_TRANSITION' and column_name='BUTTON_ICON_PATH' and nullable='N') LOOP
		execute immediate 'alter table csr.flow_state_transition modify button_icon_path null';
	end loop;
end;
/

alter table csrimp.flow_state_transition modify button_icon_path null;

declare
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'FLOW_STATE_TRANS_HELPER'
	);
	for i in 1 .. v_list.count loop
		dbms_output.put_line('Doing '||v_list(i));
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => v_list(i),
			policy_name     => (SUBSTR(v_list(i), 1, 26) || '_POL'), 
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	end loop;
end;
/

@../csrimp/imp_body

@update_tail
