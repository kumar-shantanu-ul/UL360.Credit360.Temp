-- Please update version.sql too -- this keeps clean builds in sync
define version=1540
@update_header


begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_owner, object_name, policy_name from all_policies where object_owner='CHAIN' and object_name='CUSTOMER_OPTIONS') loop
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (ALLOW_CC_ON_INVITE NUMBER(1) DEFAULT 1 NOT NULL);

declare
	v_found number;
begin				
	-- verify that the table has an app_sid column (dev helper)
	select count(*) 
	  into v_found
	  from all_tab_columns 
	 where owner = 'CHAIN' 
	   and table_name = 'CUSTOMER_OPTIONS'
	   and column_name = 'APP_SID';
	
	if v_found = 0 then
		raise_application_error(-20001, 'CHAIN.CUSTOMER_OPTIONS does not have an app_sid column');
	end if;
	
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'CUSTOMER_OPTIONS',
		policy_name     => 'CUSTOMER_OPTIONS_POLICY',
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static );				    
end;
/

@..\chain\invitation_body
@..\chain\helper_body

@update_tail