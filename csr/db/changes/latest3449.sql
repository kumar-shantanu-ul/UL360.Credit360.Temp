define version=3449
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

CREATE TABLE CSRIMP.STD_FACTOR_SET_ACTIVE(
	CSRIMP_SESSION_ID       NUMBER(10, 0)   DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	STD_FACTOR_SET_ID		NUMBER(10, 0)   NOT NULL,
	CONSTRAINT PK_STD_FACTOR_SET_ACTIVE PRIMARY KEY (CSRIMP_SESSION_ID, STD_FACTOR_SET_ID),
	CONSTRAINT FK_STD_FACTOR_SET_ACTIVE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);




GRANT SELECT, INSERT, UPDATE ON csrimp.std_factor_set_active TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.std_factor_set_active TO csrimp;








DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_api_resource_sid				security.security_pkg.T_SID_ID;
	v_health_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
		BEGIN
			v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'api.audits');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.web_pkg.CreateResource(v_act, v_www_root, v_api_resource_sid, 'health', v_health_resource_sid);
		security.acl_pkg.AddACE(
			v_act, security.acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (95, 'Emission Profile import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (95, 'Emission Profile import', 'Credit360.ExportImport.Import.Batched.Importers.EmissionProfileImporter');
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_api_resource_sid				security.security_pkg.T_SID_ID;
	v_health_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);
	-- Add public api.scheduledExport/health endpoint
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
		BEGIN
			v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'api.scheduledExport');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.web_pkg.CreateResource(v_act, v_www_root, v_api_resource_sid, 'health', v_health_resource_sid);
		security.acl_pkg.AddACE(
			v_act, security.acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_api_resource_sid				security.security_pkg.T_SID_ID;
	v_health_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);
	-- Add public api.forms/health endpoint
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
		BEGIN
			v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'api.forms');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.web_pkg.CreateResource(v_act, v_www_root, v_api_resource_sid, 'health', v_health_resource_sid);
		security.acl_pkg.AddACE(
			v_act, security.acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
	-- Add public api.regions/health endpoint
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
		BEGIN
			v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'api.regions');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.web_pkg.CreateResource(v_act, v_www_root, v_api_resource_sid, 'health', v_health_resource_sid);
		security.acl_pkg.AddACE(
			v_act, security.acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/






@..\..\..\aspen2\cms\db\form_response_import_pkg
@..\alert_pkg
@..\factor_pkg
@..\schema_pkg


@..\sheet_report_body
@..\..\..\aspen2\cms\db\form_response_import_body
@..\issue_report_body
@..\non_compliance_report_body
@..\enable_body
@..\alert_body
@..\csr_app_body
@..\factor_body
@..\schema_body
@..\csrimp\imp_body



@update_tail
