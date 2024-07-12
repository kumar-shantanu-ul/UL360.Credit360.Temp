define version=3400
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



ALTER TABLE CSR.CUSTOMER ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (UL_DESIGN_SYSTEM_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));










DECLARE
	v_reg_users_sid							security.security_pkg.T_SID_ID;
	v_act_id								security.security_pkg.T_ACT_ID;
	v_root_menu_sid							security.security_pkg.T_SID_ID;
	v_admin_menu_sid						security.security_pkg.T_SID_ID;
	v_disclosures_admin_menu_sid			security.security_pkg.T_SID_ID;
	v_frameworks_menu_sid					security.security_pkg.T_SID_ID;
	v_www_sid								security.security_pkg.T_SID_ID;
	v_www_app_sid							security.security_pkg.T_SID_ID;
	v_www_app_ui_disclosures_admin_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT DISTINCT so.application_sid_id, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE so.name = 'ui.disclosures.admin'
	) LOOP
		security.user_pkg.logonadmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');
		-- menu items
		v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id, 'menu');
		v_disclosures_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, 'framework_disclosures');
		v_frameworks_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_disclosures_admin_menu_sid, 'framework_disclosures_frameworks');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_disclosures_admin_menu_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_disclosures_admin_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_frameworks_menu_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_frameworks_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		-- web resource
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
		v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'app');
		v_www_app_ui_disclosures_admin_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_app_sid, 'ui.disclosures.admin');
		security.securableobject_pkg.ClearFlag(v_act_id, v_www_app_ui_disclosures_admin_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_disclosures_admin_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_disclosures_admin_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/






@..\period_pkg
@..\branding_pkg
@..\audit_pkg


@..\period_body
@..\enable_body
@..\branding_body
@..\csrimp\imp_body
@..\customer_body
@..\schema_body
@..\audit_body



@update_tail
