define version=1084
@update_header

DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_tg_class_id		security.security_pkg.T_CLASS_ID;
BEGIN	
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	
	-- get TagGroup class id
	v_tg_class_id := security.class_pkg.getClassID('DonationsTagGroup');
	
	-- remove the latest1074.sql PERMISSION_WRITE mapping

	DELETE FROM security.PERMISSION_MAPPING
	 WHERE parent_class_id = security.security_pkg.SO_CONTAINER
	   AND parent_permission = security.security_pkg.PERMISSION_WRITE
	   AND child_class_id = v_tg_class_id
	   AND child_permission = 16777216;
	   
	BEGIN
		-- map to read now
		security.class_pkg.CreateMapping(v_act_id, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_READ, v_tg_class_id, 
			16777216);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
END;
/

-- rls stuff
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
declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'FUNDING_COMMITMENT',
		'FC_BUDGET',
		'FC_DONATION',
		'FC_UPLOAD',
		'FC_TAG',
		'RECIPIENT_TAG_GROUP'
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
				end;
			end loop;
		end;
	end loop;
end;
/


@update_tail
