-- Please update version.sql too -- this keeps clean builds in sync
define version=1880
@update_header

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'AGGR_REGION',
        'FLOW_STATE_GROUP',
        'FLOW_STATE_GROUP_MEMBER',
        'INITIATIVE_METRIC_IND'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

@update_tail
