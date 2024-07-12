-- Please update version.sql too -- this keeps clean builds in sync
define version=1533
@update_header

ALTER TABLE csr.issue_user RENAME TO issue_involvement;
BEGIN
	FOR r IN (
		SELECT * FROM all_constraints WHERE OWNER ='CSR' AND constraint_name = 'FK_ISSUE_USER_ISSUE'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_involvement RENAME CONSTRAINT fk_issue_user_issue TO fk_issue_involvement_issue';
	END LOOP;
END;
/
ALTER INDEX csr.ix_issue_user_user RENAME TO ix_issue_involvement_user;
ALTER TABLE csr.issue_involvement ADD role_sid NUMBER(10, 0);
ALTER TABLE csr.issue_involvement ADD CONSTRAINT fk_issue_involvement_role
	FOREIGN KEY (app_sid, role_sid) REFERENCES csr.role (app_sid, role_sid);

CREATE INDEX csr.ix_issue_involvement_role ON csr.issue_involvement(app_sid, role_sid);
	
ALTER TABLE csr.issue_involvement ADD CONSTRAINT chk_issue_xor_involved CHECK ((user_sid IS NOT NULL AND role_sid IS NULL) OR (user_sid IS NULL AND role_sid IS NOT NULL));
ALTER TABLE csr.issue_involvement ADD CONSTRAINT uk_issue_involvement UNIQUE (app_sid, issue_id, user_sid, role_sid);
ALTER TABLE csr.issue_involvement DROP CONSTRAINT pk_issue_user;
ALTER TABLE csr.issue_involvement MODIFY user_sid NULL;

CREATE OR REPLACE VIEW csr.v$issue_involved_user AS
	SELECT ii.app_sid, ii.issue_id, MAX(ii.is_an_owner) is_an_owner, cu.csr_user_sid user_sid, cu.user_name, 
	       cu.full_name, cu.email, CASE WHEN MAX(ii.role_sid) IS NOT NULL THEN 1 ELSE 0 END from_role
	  FROM issue_involvement ii
	  JOIN issue i
	    ON i.app_sid = ii.app_sid
	   AND i.issue_id = ii.issue_id
	  LEFT JOIN region_role_member rrm
	    ON rrm.app_sid = i.app_sid
	   AND rrm.region_sid = i.region_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr_user cu
	    ON ii.app_sid = cu.app_sid AND NVL(ii.user_sid, rrm.user_sid) = cu.csr_user_sid
	 GROUP BY cu.csr_user_sid, ii.app_sid, ii.issue_id, cu.user_name, cu.full_name, cu.email;
	 

begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_name, policy_name from all_policies where object_owner='CSR' and object_name='ISSUE_INVOLVEMENT') loop
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

declare
	v_found number;
begin				
	-- verify that the table has an app_sid column (dev helper)
	select count(*) 
	  into v_found
	  from all_tab_columns 
	 where owner = 'CSR' 
	   and table_name = 'ISSUE_INVOLVEMENT'
	   and column_name = 'APP_SID';
	
	if v_found = 0 then
		raise_application_error(-20001, 'CSR.ISSUE_INVOLVEMENT does not have an app_sid column');
	end if;
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'ISSUE_INVOLVEMENT',
		policy_name     => 'ISSUE_INVOLVEMENT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );				    
end;
/

ALTER TABLE csrimp.issue_user RENAME TO issue_involvement;
ALTER TABLE csrimp.issue_involvement RENAME CONSTRAINT fk_issue_user_is TO fk_issue_involvement_is;
ALTER TABLE csrimp.issue_involvement ADD role_sid NUMBER(10, 0);
ALTER TABLE csrimp.issue_involvement ADD CONSTRAINT uk_issue_involvement UNIQUE (csrimp_session_id, issue_id, user_sid, role_sid);
ALTER TABLE csrimp.issue_involvement DROP CONSTRAINT pk_issue_user;
ALTER TABLE csrimp.issue_involvement MODIFY user_sid NULL;

@..\issue_pkg
@..\audit_body
@..\csr_data_body
@..\csr_user_body
@..\csrimp\imp_body
@..\issue_body
@..\meter_monitor_body
@..\quick_survey_body
@..\schema_body
@..\supplier_body
@..\chain\company_user_body

DROP VIEW csr.v$issue_user;

@update_tail