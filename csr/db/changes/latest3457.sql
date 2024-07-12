define version=3457
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



UPDATE ASPEN2.APPLICATION SET BRANDING_SERVICE_ENABLED = 1 WHERE BRANDING_SERVICE_ENABLED = 2;
ALTER TABLE ASPEN2.APPLICATION DROP COLUMN BRANDING_SERVICE_CSS;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION DROP COLUMN BRANDING_SERVICE_CSS:

ALTER TABLE CSRIMP.APPLICATION
  ADD BLOCK_SA_LOGON NUMBER(1) DEFAULT 0 NOT NULL;

BEGIN
	security.user_pkg.logonadmin;
    FOR r in (
        select sid_Id from security.securable_object where name = 'Enable Delegation Overlap Warning'
    )
    LOOP
        security.securableobject_pkg.deleteso(security.security_pkg.getact, r.sid_id);
    END LOOP;
    delete from csr.capability where name = 'Enable Delegation Overlap Warning';
END;
/
BEGIN
 INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION)
 VALUES ('Enable roll forward on indicators', 0, 'Enable the legacy functionality for roll forward on indicators. Do not ENABLE without reference to Product.');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
DECLARE
	v_act_id_unused					security.security_pkg.T_ACT_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	PROCEDURE EnableCapability(
		in_capability  					IN	security.security_pkg.T_SO_NAME,
		in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
	)
	AS
		v_allow_by_default      csr.capability.allow_by_default%TYPE;
		v_capability_sid		security.security_pkg.T_SID_ID;
		v_capabilities_sid		security.security_pkg.T_SID_ID;
	BEGIN
		-- this also serves to check that the capability is valid
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;
		-- just create a sec obj of the right type in the right place
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath_(SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				in_capability,
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				IF in_swallow_dup_exception = 0 THEN
					RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
				END IF;
		END;
	END;
BEGIN
	FOR r IN (
	SELECT host, app_sid
		  FROM csr.customer
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_groups_sid := security.securableobject_pkg.GetSIDFromPath_(r.app_sid, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSIDFromPath_(v_groups_sid, 'RegisteredUsers');
        
		-- enable capability
		  EnableCapability('Enable roll forward on indicators');		
		-- grant permission to registered users
			security.acl_pkg.AddACE(v_act_id_unused,
			security.acl_pkg.GetDACLIDForSID(
				security.securableobject_pkg.GetSIDFromPath_(r.app_sid, 'Capabilities/Enable roll forward on indicators')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;
/
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_csr_resource_sid				security.security_pkg.T_SID_ID;
	v_sasso_resource_sid			security.security_pkg.T_SID_ID;
	v_ssopage_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);
	-- Add csr\sasso and csr\sasso\singlesignon.acds
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
			v_csr_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'csr');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
		security.web_pkg.CreateResource(v_act, v_www_root, v_csr_resource_sid, 'sasso', v_sasso_resource_sid);
		security.web_pkg.CreateResource(v_act, v_www_root, v_sasso_resource_sid, 'singlesignon.acds', v_ssopage_resource_sid);
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ssopage_resource_sid), -1, 
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (76, 'Block non-SSO superadmin logon', 'Block superadmin logons from login page. Use with caution!', 'BlockSaLogon', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (76, 'Block/unblock', '(1 block, 0 unblock)', 0, '1');






@..\factor_pkg
@..\factor_set_group_pkg
@..\unit_test_pkg
@..\enable_pkg
@..\branding_pkg
@..\util_script_pkg


@..\audit_body
@..\deleg_plan_body
@..\factor_body
@..\factor_set_group_body
@..\util_script_body
@..\unit_test_body
@..\enable_body
@..\flow_body
@..\..\..\aspen2\db\aspenapp_body
@..\branding_body
@..\schema_body
@..\site_name_management_body
@..\csrimp\imp_body



@update_tail
