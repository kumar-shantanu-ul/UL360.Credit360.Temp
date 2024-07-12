-- Please update version.sql too -- this keeps clean builds in sync
define version=1243
@update_header

INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('value_chain_report_primary', 'Value Chain Report - Primary', 8);

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
			v_vc_users_group			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Users');
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_vc_menu					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'vc_dashboard');
			v_vc_reports				security.security_pkg.T_SID_ID;
		BEGIN
			
			BEGIN
				v_vc_reports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_reports');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_reports',  'Value chain reports',  '/csr/site/ct/reportDownload.acds',  0, null, v_vc_reports);

					-- don't inherit dacls, clean existing ACE's
					security.securableobject_pkg.SetFlags(v_act_id, v_vc_reports, 0);
					security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_reports));

					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_reports), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
						security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
			END;
		END;		
	END LOOP;
	
	security.user_pkg.Logonadmin();
END;
/

@update_tail