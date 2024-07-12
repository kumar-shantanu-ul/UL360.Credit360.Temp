-- Please update version.sql too -- this keeps clean builds in sync
define version=1204
@update_header

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT c.host, co.is_value_chain FROM csr.customer c, ct.customer_options co WHERE c.app_sid = co.app_sid
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			-- well known sids	
			v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
			v_admins_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
			v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_csr_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_everyone_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
			v_reg_users_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
			-- our sids	
			v_hu_group					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Hotspot Users');
			v_rhu_group					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Restricted Hotspot Users');
			v_ct_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_sid, 'ct');
			v_ct_hs_site_sid			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'hotspotter');
			v_ct_hs_m_site_sid			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_hs_site_sid, 'manage');
			v_ct_mgmt_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'management');
			v_hotspot_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'hotspot_dashboard');
			v_admin_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
			v_capabilities_sid			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'capabilities');
			--v_template_upload_menu		security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			--v_demo_menu					security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			--v_setup_menu				security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			v_hs_wiz_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'wizard');
			v_hs_breakdown_menu			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'breakdown');
		
			v_hs_report_menu			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'reports');
			v_about_menu				security.security_pkg.T_SID_ID;-- DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'ct_hs_about');
			--v_data_menu					security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			--v_analysis_menu				security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			--v_chain_menu				security.security_pkg.T_SID_ID DEFAULT xxxxxxxxxx;
			v_manage_templates			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Manage CT Templates');
		
			v_ec_users_group			security.security_pkg.T_SID_ID;
			v_ec_admins_group			security.security_pkg.T_SID_ID;
			v_bt_users_group			security.security_pkg.T_SID_ID;
			v_bt_admins_group			security.security_pkg.T_SID_ID;
			v_ps_users_group			security.security_pkg.T_SID_ID;
			v_ps_admins_group			security.security_pkg.T_SID_ID;
			v_up_users_group			security.security_pkg.T_SID_ID;
			v_up_admins_group			security.security_pkg.T_SID_ID;
			v_vc_users_group			security.security_pkg.T_SID_ID;
			v_vc_admins_group			security.security_pkg.T_SID_ID;
			-- menus
			v_vc_menu					security.security_pkg.T_SID_ID;
			v_vc_ec_menu				security.security_pkg.T_SID_ID;
			v_vc_bt_menu				security.security_pkg.T_SID_ID;
			v_vc_ps_menu				security.security_pkg.T_SID_ID;
			v_vc_up_menu				security.security_pkg.T_SID_ID;
			v_admin_apport_menu			security.security_pkg.T_SID_ID;
			v_admin_config_menu			security.security_pkg.T_SID_ID;
			-- web resources
			v_ct_public_sid				security.security_pkg.T_SID_ID;
			v_ct_admin_sid				security.security_pkg.T_SID_ID;
			v_ct_ec_sid					security.security_pkg.T_SID_ID;
			v_ct_bt_sid					security.security_pkg.T_SID_ID;
			v_ct_ps_sid					security.security_pkg.T_SID_ID;
			v_ct_up_sid					security.security_pkg.T_SID_ID;
			-- capabilities
			v_admin_ec_cap_sid			security.security_pkg.T_SID_ID;
			v_admin_bt_cap_sid			security.security_pkg.T_SID_ID;
			v_admin_ps_cap_sid			security.security_pkg.T_SID_ID;
			v_admin_up_cap_sid			security.security_pkg.T_SID_ID;
			v_edit_ec_cap_sid			security.security_pkg.T_SID_ID;
			v_edit_bt_cap_sid			security.security_pkg.T_SID_ID;
			v_edit_ps_cap_sid			security.security_pkg.T_SID_ID;
			v_edit_up_cap_sid			security.security_pkg.T_SID_ID;	
		BEGIN
			
			BEGIN
				v_about_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'about');
				security.securableobject_pkg.RenameSO(v_act_id, v_about_menu, 'ct_hs_about');
			EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
			END;
			v_about_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'ct_hs_about');
			
			FOR s IN (
				SELECT sid_id FROM security.securable_object WHERE sid_id IN (
					v_ct_site_sid,
					v_ct_hs_site_sid,
					v_ct_hs_m_site_sid,
					v_ct_mgmt_sid,
					v_hotspot_menu,
					v_hs_wiz_menu,
					v_hs_breakdown_menu,
					v_hs_report_menu,
					v_about_menu,
					v_manage_templates
				)
			)
			LOOP
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(s.sid_id));
				security.acl_pkg.ResetDescendantACLs(v_act_id, s.sid_id);
			END LOOP;		
			
			
			IF r.is_value_chain = 1 THEN
				v_ec_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Employee Commute Admins');
				v_ec_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Employee Commute Users');
				v_bt_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Business Travel Admins');
				v_bt_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Business Travel Users');
				v_bt_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Business Travel Users');
				v_ps_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Products Services Admins');
				v_ps_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Products Services Users');
				v_up_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Use Phase Admins');
				v_up_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Use Phase Users');
				v_vc_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Admins');
				v_vc_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Users');
				v_ct_public_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'public');
				v_ct_admin_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'admin');
				v_ct_ec_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'ec');
				v_ct_bt_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'bt');
				v_ct_ps_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'ps');
				v_ct_up_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'up');
				v_vc_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'vc_dashboard');
				v_vc_ec_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_ec_landing');
				v_vc_bt_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_bt_landing');
				v_vc_ps_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_ps_landing');
				v_vc_up_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_up_landing');
				v_admin_apport_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'vc_apportionment');
				v_admin_config_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'vc_module_config');
				v_admin_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Employee Commuting');
				v_admin_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Business Travel');
				v_admin_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Products Services');
				v_admin_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Use Phase');
				v_edit_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Employee Commuting');
				v_edit_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Business Travel');
				v_edit_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Products Services');
				v_edit_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Use Phase');
				
				FOR s IN (
					SELECT sid_id FROM security.securable_object WHERE sid_id IN (
						v_ct_public_sid,
						v_ct_admin_sid,
						v_ct_public_sid,
						v_ct_bt_sid,
						v_ct_ps_sid,
						v_ct_up_sid,
						v_vc_menu,
						v_vc_ec_menu,
						v_vc_bt_menu,
						v_vc_ps_menu,
						v_vc_up_menu,
						v_admin_apport_menu,
						v_admin_config_menu,
						v_admin_ec_cap_sid,
						v_admin_bt_cap_sid,
						v_admin_ps_cap_sid,
						v_admin_up_cap_sid,
						v_edit_ec_cap_sid,
						v_edit_bt_cap_sid,
						v_edit_ps_cap_sid,
						v_edit_up_cap_sid
					)
				)
				LOOP
					security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(s.sid_id));
					security.acl_pkg.ResetDescendantACLs(v_act_id, s.sid_id);
				END LOOP;	
				
				
			END IF;			
			
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_hs_m_site_sid, 0);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), v_rhu_group);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_mgmt_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_INHERITABLE, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hotspot_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);
			security.securableobject_pkg.SetFlags(v_act_id, v_hs_breakdown_menu, 0);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), v_rhu_group);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
			security.securableobject_pkg.SetFlags(v_act_id, v_hs_report_menu, 0);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), v_rhu_group);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_about_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
			security.securableobject_pkg.SetFlags(v_act_id, v_manage_templates, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_manage_templates));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_manage_templates), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);	
				
			
			IF r.is_value_chain = 1 THEN
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_public_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_public_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_public_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_admin_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_admin_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_admin_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_ec_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_ec_sid));
				security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_ec_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_bt_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_bt_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_bt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_ps_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ps_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ps_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_ct_up_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_up_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_up_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_vc_ec_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ec_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ec_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_vc_bt_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_bt_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_bt_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_vc_ps_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ps_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ps_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_vc_up_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_up_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_up_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_apport_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_apport_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_apport_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_config_menu, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_ec_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ec_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ec_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_bt_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_bt_cap_sid));			
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_bt_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_ps_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ps_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ps_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
				security.securableobject_pkg.SetFlags(v_act_id, v_admin_up_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_up_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_up_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
				security.securableobject_pkg.SetFlags(v_act_id, v_edit_ec_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ec_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ec_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
				security.securableobject_pkg.SetFlags(v_act_id, v_edit_bt_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_bt_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_bt_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
				security.securableobject_pkg.SetFlags(v_act_id, v_edit_ps_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ps_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ps_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
				security.securableobject_pkg.SetFlags(v_act_id, v_edit_up_cap_sid, 0);
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_up_cap_sid));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_up_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
			END IF;
		END;
	END LOOP;
END;
/

@update_tail
