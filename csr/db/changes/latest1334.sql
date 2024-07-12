-- Please update version.sql too -- this keeps clean builds in sync
define version=1334
@update_header

-- from cms/aspen2/db/changes/latest39 -- table was still hanging around on live
begin
	for r in (select owner,table_name from all_tables where owner='CMS' and table_name='APP_SCHEMA_PERMISSION') loop
		execute immediate 'drop table "'||r.owner||'"."'||r.table_name||'"';
	end loop;
end;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'FLOW_TAB_COLUMN_CONS',
		'TAB_COLUMN_ROLE_PERMISSION'		
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CMS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CMS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
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
