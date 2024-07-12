define version=3394
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE csr.quick_survey_type ADD enable_response_import NUMBER(10, 0) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.quick_survey_type ADD enable_response_import NUMBER(10, 0) DEFAULT 1 NOT NULL;


GRANT EXECUTE ON csr.delegation_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.deleg_plan_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.deleg_admin_pkg TO TOOL_USER;








BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT m.sid_id, so.application_sid_id, w.website_name
		  FROM security.menu m
		  JOIN security.securable_object so ON so.sid_id = m.sid_id
		  JOIN security.website w ON w.application_sid_id = so.application_sid_id
		 WHERE m.action = '/csr/site/delegation/manage/editPlan.acds'
	) LOOP
		security.user_pkg.logonadmin(r.website_name);
		security.securableobject_pkg.DeleteSO(sys_context('security', 'act'), r.sid_id);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Delegation Plan Folders', 0, 'Delegations: Enable foldering for delegation plans in Manage Delegation Plans.');






@..\quick_survey_pkg
@..\deleg_plan_pkg


@..\deleg_plan_body
@..\quick_survey_body
@..\csrimp\imp_body
@..\enable_body
@..\automated_export_body



@update_tail
