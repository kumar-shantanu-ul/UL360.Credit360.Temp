define version=3483
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

CREATE TABLE CSR.CUSTOMER_FEATURE_FLAGS(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FEATURE_FLAG_SCRAG_A    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    FEATURE_FLAG_SCRAG_B    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    FEATURE_FLAG_SCRAG_C    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK_CUSTOMER_FEATURE_FLAGS PRIMARY KEY (APP_SID),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_A CHECK (FEATURE_FLAG_SCRAG_A IN (0, 1)),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_B CHECK (FEATURE_FLAG_SCRAG_B IN (0, 1)),
    CONSTRAINT CHK_CUSTOMER_FEATURE_FLAGS_SCRAG_C CHECK (FEATURE_FLAG_SCRAG_C IN (0, 1))
)
;




grant select on cms.sys_schema to csr;








BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT DISTINCT application_sid_id, website_name
		  FROM security.website sec
		  JOIN csr.customer c
		    ON sec.application_sid_id = c.app_sid
		 WHERE LOWER(c.site_type) = 'staff'
	)
	LOOP
		security.user_pkg.LogonAdmin(r.website_name);
		UPDATE aspen2.application
		   SET ga4_enabled = 0
		 WHERE app_sid = r.application_sid_id;
		security.user_pkg.LogonAdmin();
	END lOOP;
END;
/	
INSERT INTO csr.capability (name, allow_by_default, description) 
VALUES ('Enable Temporal Aggregation on Measure Conversion Flycalcs', 0, 'Enable Temporal Aggregation on Measure Conversion Flycalcs');
DECLARE
	v_admin_menu_sid			security.security_pkg.T_SID_ID;
	v_superadmin_sid			security.security_pkg.T_SID_ID;
	v_www_ui_notifications  	security.security_pkg.T_SID_ID;
	v_app_ui_notifications		security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_admins					security.security_pkg.T_SID_ID;
	v_ui_notifications_dacl 	NUMBER(10);
	v_ui_app_notifications_dacl	NUMBER(10);
	v_act						security.security_pkg.T_ACT_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		BEGIN
			v_admin_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.app_sid, 'menu/admin');
			v_superadmin_sid := security.securableobject_pkg.getsidfrompath(v_act, 0, 'csr/SuperAdmins');
			security.menu_pkg.CreateMenu(
				in_act_id => v_act,
				in_parent_sid_id => v_admin_menu_sid,
				in_name => 'failednotications',
				in_description => 'Failed notifications',
				in_action => '/app/ui.notifications/notifications',
				in_pos => NULL,
				in_context => NULL,
				out_sid_id => v_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.app_sid, 'menu/admin/failednotications');
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		BEGIN
			security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act, security.acl_pkg.GetDACLIDForSID(v_sid));
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		END;
		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'wwwroot');
			v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'app');
			-- web resource for the ui
			BEGIN
				v_www_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'ui.notifications');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_www_root, 'ui.notifications', v_www_ui_notifications);
			END;
			-- web resource for the ui
			BEGIN
				v_app_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_app_sid, 'ui.notifications');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_www_app_sid, 'ui.notifications', v_www_ui_notifications);
			END;
			v_ui_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_www_ui_notifications);
			v_ui_app_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_app_ui_notifications);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_notifications_dacl
			);
		
			-- Read/write www ui for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_app_notifications_dacl
			);
		
			-- Read/write app ui for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_app_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	v_fd_menu_sid				security.security_pkg.T_SID_ID;
	v_fd_assignments_menu_sid	security.security_pkg.T_SID_ID;
	v_fd_disclosures_menu_sid	security.security_pkg.T_SID_ID;
	v_fd_frameworks_menu_sid	security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_disclosures_admin_sid		security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout 	=> 172800,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id
		);
		v_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Menu');
		BEGIN
			v_fd_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_sid, 'framework_disclosures');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				BEGIN
					v_fd_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_sid, 'ui.disclosures_disclosures');
				EXCEPTION
					WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
						v_fd_menu_sid := NULL;
				END;
		END;
		IF v_fd_menu_sid IS NOT NULL THEN
			security.SecurableObject_pkg.RenameSO(v_act_id, v_fd_menu_sid, 'ui.disclosures_disclosures');
			security.menu_pkg.SetMenuAction(v_act_id, v_fd_menu_sid, '/app/ui.disclosures/disclosures#/');
			v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');
			v_disclosures_admin_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/Framework Disclosure Admins');
			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'assignments',
					in_description => 'Assignments',
					in_action => '/app/ui.disclosures/disclosures#/',
					in_pos => 1,
					in_context => NULL,
					out_sid_id => v_fd_assignments_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_assignments_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/assignments');
			END;
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_assignments_menu_sid), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_assignments_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'disclosures',
					in_description => 'Disclosures',
					in_action => '/app/ui.disclosures/disclosures#/disclosures',
					in_pos => 2,
					in_context => NULL,
					out_sid_id => v_fd_disclosures_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_disclosures_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/disclosures');
			END;
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_disclosures_menu_sid), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_disclosures_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'frameworks',
					in_description => 'Frameworks',
					in_action => '/app/ui.disclosures/disclosures#/frameworks',
					in_pos => 3,
					in_context => NULL,
					out_sid_id => v_fd_frameworks_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_frameworks_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/frameworks');
			END;
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_frameworks_menu_sid), v_disclosures_admin_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_frameworks_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_disclosures_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END IF;
		security.user_pkg.logonadmin();
	END LOOP;
END;
/






@..\scenario_run_pkg


@..\csr_app_body
@..\csr_user_body
@..\zap_body
@..\scenario_run_body
@..\stored_calc_datasource_body
@..\notification_body
@..\enable_body



@update_tail
