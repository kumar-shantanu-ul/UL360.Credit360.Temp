-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

GRANT EXECUTE ON csr.appSidCheck TO chain;

-- For each chain policy, drop it and use the CSR version and naming convention (so that clean builds
-- and old builds have the same names where possible).
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
	) LOOP
		dbms_rls.drop_policy(
			object_schema   => 'CHAIN',
			object_name     => r.object_name,
			policy_name     => r.policy_name
		);
        declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					if v_i = 1 then
						v_name := SUBSTR(r.object_name, 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(r.object_name, 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => r.object_owner,
				        object_name     => r.object_name,
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive);
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
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

DROP FUNCTION chain.nullableAppSidCheck;
DROP FUNCTION chain.appSidCheck;

-- Data

-- ** New package grants **

-- *** Packages ***
@..\chain\helper_pkg
@..\chain\helper_body
@..\chain\setup_body

@update_tail
