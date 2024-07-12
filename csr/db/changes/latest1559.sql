-- Please update version.sql too -- this keeps clean builds in sync
define version=1559
@update_header

CREATE OR REPLACE FUNCTION csrimp.SessionIDCheck (
	in_schema 						IN	VARCHAR2, 
	in_object 						IN	VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- return '' if the CSRIMP_SESSION_ID is not set to prevent "ORA-28133: full table access is restricted by fine-grained security" errors in 11g when running update scripts
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NULL THEN
		RETURN '';
	END IF;
		
	RETURN 'csrimp_session_id = sys_context(''SECURITY'', ''CSRIMP_SESSION_ID'')';
END;
/


-- although not normally a good plan this only affects csrimp, not the website
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE pf_owner = 'CSRIMP' AND function IN ('SESSIONIDCHECK')
		   AND object_owner IN ('CSRIMP', 'CMS')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
END;
/

ALTER TABLE csrimp.dataview ADD rank_limit_left                NUMBER(10, 0)      DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.dataview ADD rank_ind_sid                   NUMBER(10, 0);
ALTER TABLE csrimp.dataview ADD rank_missing_values_treatment  NUMBER(10, 0);
ALTER TABLE csrimp.dataview ADD rank_limit_right               NUMBER(10, 0)      DEFAULT 0 NOT NULL;

@..\csrimp\imp_body
@..\schema_body
 
@update_tail
