DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
begin
	for r in (
		select atc.owner, atc.table_name, atc.nullable,
		       case atc.owner 
					when 'CHAIN' then 'CSR'
					else atc.owner 
				end function_schema
		  from dba_tab_columns atc, (
				select owner, table_name
				  from dba_tables
				 where owner IN ('CSR', 'CHAIN', 'CMS', 'ACTIONS', 'CHEM', 'CT', 'DONATIONS', 'ETHICS', 'SUPPLIER', 'CAMPAIGNS')
				   and temporary = 'N'
				 minus
				-- exclude views
				select owner, view_name
				  from dba_views
				 where owner IN ('CSR', 'CHAIN', 'CMS', 'ACTIONS', 'CHEM', 'CT', 'DONATIONS', 'ETHICS', 'SUPPLIER', 'CAMPAIGNS')
				 minus
				-- and tables that already have a policy checking the app_sid
				select object_owner, object_name
				  from dba_policies
				 where object_owner IN ('CSR', 'CHAIN', 'CMS', 'ACTIONS', 'CHEM', 'CT', 'DONATIONS', 'ETHICS', 'SUPPLIER', 'CAMPAIGNS')
				   and pf_owner IN ('CSR', 'CMS', 'ACTIONS', 'CHEM', 'CT', 'DONATIONS', 'ETHICS', 'SUPPLIER', 'CAMPAIGNS')
				    -- no need for CHAIN in the pf_owner check because the policies for chain are owned by csr
				   and upper(function) in ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')) at
	   where at.owner IN ('CSR', 'CHAIN', 'CMS', 'ACTIONS', 'CHEM', 'CT', 'DONATIONS', 'ETHICS', 'SUPPLIER', 'CAMPAIGNS')
	     and at.owner = atc.owner
	     and at.table_name = atc.table_name
	     and atc.column_name = 'APP_SID'
	) loop
		-- a nullable app_sid column is an absolutely awful design
		-- we've got one actual table in CSR that does this (it should really be fixed)
		-- and one materialized view log (which is ok since it's just an artefact of
		-- how the materialized view refresh works)
		-- DO NOT MIX SHARED AND CUSTOMER SPECIFIC DATA INTO THE SAME TABLE
		if r.nullable = 'Y' and r.table_name not in ('PLUGIN') then
			raise_application_error(-20001, r.owner||'.'||r.table_name||
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
					--dbms_output.put_line('doing '||v_name||' ('||r.owner||')');

				    dbms_rls.add_policy(
				        object_schema   => r.owner,
				        object_name     => r.table_name,
				        policy_name     => v_name,
				        function_schema => r.function_schema,
				        policy_function => (CASE WHEN r.nullable = 'N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        -- SPECIAL CASE FOR APP_LOCK
						-- We believe we've found a bug in 10g that's causing a problem when calling csr_data_pkg.LockApp.
						-- After the update statement sets the dummy row in csr.app_lock, SQL%ROWCOUNT is sometimes zero, 
						-- even though the row exists for the app sid and the context appears to be set correctly.
						-- We've done extensive testing to rule out anything other then a possible bug in 10g.
						-- Setting the rls policy type to 'dynamic' instead of 'context_sensitive' prevents the issue we are seeing.
				        policy_type     => (CASE WHEN r.table_name = 'APP_LOCK' THEN dbms_rls.dynamic ELSE dbms_rls.context_sensitive END) );
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

