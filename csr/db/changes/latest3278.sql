define version=3278
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/


ALTER TABLE CSR.CUSTOMER ADD USE_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_USE_BETA_MENU CHECK (USE_BETA_MENU IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD USE_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (USE_BETA_MENU DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_USE_BETA_MENU CHECK (USE_BETA_MENU IN (0,1));










BEGIN
	SYS.DBMS_SCHEDULER.DROP_JOB (job_name  => 'CSR.EXPIRE_REMOTE_JOBS');
	/*
	-- If we need to reinstate this at a later point, this is what it should have been.
	dbms_scheduler.create_job (
		job_name		=> 'CSR.EXPIRE_REMOTE_JOBS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.meter_processing_job_pkg.ExpireJobs;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2020/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MINUTELY;INTERVAL=10',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Roll-back or expire meter processing jobs that are no longer locked but in a status that means they were processing'
	);
	*/
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (109, 'Formeditor', 'EnableForms', 'Enable form editor');
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_www_api_security	security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		  JOIN security.website w ON LOWER(c.host) = LOWER(w.website_name)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_act_id := security.security_pkg.getact;
		v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		-- web resource for the api
		BEGIN
			v_www_api_security := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.security');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.security', v_www_api_security);
		END;
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_security), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/






@..\branding_pkg
@..\meter_processing_job_pkg
@..\enable_pkg


@..\..\..\aspen2\cms\db\form_body
@..\branding_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body
@..\meter_processing_job_body
@..\enable_body
@..\issue_body
@..\chain\company_filter_body



@update_tail
