define version=1085
@update_header

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_exists number;
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
			select count(*) 
			  into v_exists
			  from all_policies 
			 where object_owner='DONATIONS' and object_name = v_list(i);
			if v_exists = 0 then
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
					end;
				end loop;
			end if;
		end;
	end loop;
end;
/

@update_tail
