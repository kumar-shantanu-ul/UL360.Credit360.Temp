@@security_functions

/*
select distinct utc.table_name, utc.nullable  from user_tab_columns utc, sys.tab t 
 where utc.column_name='APP_SID' and t.tname = utc.table_name and t.tabtype <> 'VIEW' 
order by utc.nullable, utc.table_name;
*/

begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_name, policy_name from all_policies where object_owner='DONATIONS') loop
		dbms_rls.drop_policy(
            object_schema   => 'DONATIONS',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'BUDGET',
		'BUDGET_CONSTANT',
		'CONSTANT',
		'CUSTOMER_DEFAULT_EXRATE',
		'CUSTOM_FIELD_DEPENDENCY',
		'CUSTOMER_OPTIONS',
		'CUSTOMER_FILTER_FLAG',
		'CUSTOM_FIELD',
		'DONATION',
		'DONATION_DOC',
		'DONATION_STATUS',
		'DONATION_TAG',
		'FUNDING_COMMITMENT',
		'FC_BUDGET',
		'FC_DONATION',
		'FC_UPLOAD',
		'FC_TAG',
		'FILTER',
		'LETTER_BODY_REGION_GROUP',
		'LETTER_BODY_TEXT',
		'LETTER_TEMPLATE',
		'RECIPIENT',
		'RECIPIENT_TAG',
		'RECIPIENT_TAG_GROUP',
		'REGION_GROUP',
		'REGION_GROUP_MEMBER',
		'REGION_GROUP_RECIPIENT',
		'SCHEME',
		'SCHEME_FIELD',
		'SCHEME_DONATION_STATUS',
		'SCHEME_TAG_GROUP',
		'TAG',
		'TAG_GROUP',
		'TAG_GROUP_MEMBER',
		'TRANSITION',
		'USER_FIELDSET',
		'USER_FIELDSET_FIELD'
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
					
					-- dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'DONATIONS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'DONATIONS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/
