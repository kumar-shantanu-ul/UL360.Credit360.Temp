-- Please update version.sql too -- this keeps clean builds in sync
define version=2511
@update_header

declare
	v_exists number;
	v_cust_pk varchar(30);
begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='INBOUND_CMS_ACCOUNT' and column_name='APP_SID' and nullable='Y') loop
		execute immediate 'alter table csr.inbound_cms_account modify app_sid not null';
	end loop;
	select constraint_name
	  into v_cust_pk
	  from all_constraints
	 where table_name='CUSTOMER' and constraint_type='P' and owner='CSR';
	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CSR' and table_name='INBOUND_CMS_ACCOUNT' and constraint_type='R' 
	   and r_owner='CSR' and r_constraint_name=v_cust_pk;
	if v_exists = 0 then
		execute immediate 'ALTER TABLE CSR.INBOUND_CMS_ACCOUNT ADD CONSTRAINT FK_INBOUND_CMS_ACCOUNT_CUST FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID)';
	end if;
end;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
begin
	for r in (select atc.table_name, atc.nullable
				from all_tab_columns atc, all_tables at
			   where at.owner = 'CSR'
			     and at.owner = atc.owner
			     and at.table_name = atc.table_name
			     and at.temporary = 'N'
			     and atc.column_name = 'APP_SID'
				 -- these exclusions can be removed when we move to 11g as MERGE and RLS are compatible there
			     and at.table_name not in (
					'AGGREGATE_IND_CALC_JOB',
					'CALC_JOB',
					'EST_JOB',
					'SHEET_VAL_CHANGE_LOG',
					'TARGET_DASHBOARD_REG_MEMBER',
					'VAL_CHANGE_LOG')
			     and (at.owner, at.table_name) not in (
				    -- exclude views
			     	select owner, view_name
			     	  from all_views
			     	 union all
			     	-- and tables that already have a policy checking the app_sid
					select object_owner, object_name
					  from all_policies
					 where object_owner = 'CSR'
					   and pf_owner = 'CSR'
					   and upper(function) in ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK'))) loop
		-- a nullable app_sid column is an absolutely awful design
		-- we've got one table in CSR that does this -- it should really be fixed
		-- DO NOT MIX SHARED AND CUSTOMER SPECIFIC DATA INTO THE SAME TABLE
		if r.nullable = 'Y' and r.table_name != 'PLUGIN' then
			raise_application_error(-20001, 'CSR.'||r.table_name||
				' has an app_sid column, but it is nullable -- go away and fix your dreadful code');
		end if;

		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					if v_i = 1 then
						v_name := SUBSTR(r.table_name, 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(r.table_name, 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => r.table_name,
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => (CASE WHEN r.nullable = 'N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
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

@update_tail
