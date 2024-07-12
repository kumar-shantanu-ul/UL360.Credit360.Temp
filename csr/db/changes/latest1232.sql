-- Please update version.sql too -- this keeps clean builds in sync
define version=1232
@update_header


BEGIN

	security.user_pkg.Logonadmin();
	
	FOR r in (
		SELECT c.host, ch.top_company_sid
		  FROM csr.customer c, chain.customer_options ch, ct.customer_options ct
		 WHERE c.app_sid = ch.app_sid
		   AND c.app_sid = ct.app_sid
		   AND ct.is_value_chain = 1
	)
	LOOP
		security.user_pkg.Logonadmin(r.host);
		
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
			v_vc_admins_group			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Admins');
			v_vc_users_group			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Users');
			v_ps_users_group			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Products Services Users');
			v_reg_users_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
			v_ucd_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
			v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_csr_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			v_site_ct_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_csr_site_sid, 'ct');
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_admin_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
			v_chain_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
			v_my_details_menu			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'my_details');
			v_site_excel_sid			security.security_pkg.T_SID_ID;
			v_supplier_details_menu		security.security_pkg.T_SID_ID;
		BEGIN
			security.group_pkg.AddMember(v_act_id, v_ucd_sid, v_vc_admins_group);
			
			BEGIN
				v_supplier_details_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_supplier_search');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_supplier_search',  'Supplier search',  '/csr/site/chain/supplierDetails.acds',  0, null, v_supplier_details_menu);

					-- don't inherit dacls, clean existing ACE's
					security.securableobject_pkg.SetFlags(v_act_id, v_supplier_details_menu, 0);
					security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_supplier_details_menu));

					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_supplier_details_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
						security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
			END;	
			
			-- give vc users permission on the my details menu item
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_my_details_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	

			-- ensure that the excel web resource is created
			BEGIN
				v_site_excel_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_sid, 'excel');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'excel', v_site_excel_sid);	

					-- give the registered users group READ permission on the resource
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_site_excel_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
			END;

			-- TODO: this should be conditional that no other chain implementations are running
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_chain_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_chain_menu));

		END;		
	END LOOP;
	
	security.user_pkg.Logonadmin();
END;
/

@..\ct\rls
@..\ct\admin_pkg
@..\ct\advice_pkg
@..\ct\breakdown_group_pkg
@..\ct\breakdown_pkg
@..\ct\breakdown_type_pkg
@..\ct\business_travel_pkg
@..\ct\classification_pkg
@..\ct\company_pkg
@..\ct\consumption_pkg
@..\ct\ct_pkg
@..\ct\emp_commute_pkg
@..\ct\excel_pkg
@..\ct\hotspot_pkg
@..\ct\link_pkg
@..\ct\products_services_pkg
@..\ct\snapshot_pkg
@..\ct\stemmer_pkg
@..\ct\supplier_pkg
@..\ct\util_pkg
@..\ct\value_chain_report_pkg

@..\ct\admin_body
@..\ct\advice_body
@..\ct\breakdown_body
@..\ct\breakdown_group_body
@..\ct\breakdown_type_body
@..\ct\business_travel_body
@..\ct\classification_body
@..\ct\company_body
@..\ct\consumption_body
@..\ct\emp_commute_body
@..\ct\excel_body
@..\ct\hotspot_body
@..\ct\link_body
@..\ct\products_services_body
@..\ct\snapshot_body
@..\ct\stemmer_body
@..\ct\supplier_body
@..\ct\util_body
@..\ct\value_chain_report_body

@update_tail
