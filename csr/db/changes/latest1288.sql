-- Please update version.sql too -- this keeps clean builds in sync
define version=1288
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
			v_everyone_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
			v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
			v_csr_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			v_site_ct_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_csr_site_sid, 'ct');
			v_ct_card_sid				security.security_pkg.T_SID_ID;
			v_ct_component_sid			security.security_pkg.T_SID_ID;
		BEGIN

			-- /csr/site/ct/cards/
			BEGIN
				v_ct_card_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'cards');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'cards', v_ct_card_sid);	

					-- don't inherit dacls, clean existing ACE's
					security.securableobject_pkg.SetFlags(v_act_id, v_ct_card_sid, 0);
					security.acl_pkg.DeleteAllACEs(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_card_sid));
					
					-- give the Everyone group READ permission on the resource
					security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_card_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
			END;
				
			-- /csr/site/ct/components/
			BEGIN
				v_ct_component_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'components');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'components', v_ct_component_sid);	

					-- don't inherit dacls, clean existing ACE's
					security.securableobject_pkg.SetFlags(v_act_id, v_ct_component_sid, 0);
					security.acl_pkg.DeleteAllACEs(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_component_sid));
					
					-- give the Everyone group READ permission on the resource
					security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_component_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
			END;

		END;		
	END LOOP;
	
	security.user_pkg.Logonadmin();
END;
/

@..\ct\emp_commute_pkg
@..\ct\emp_commute_body
@..\ct\reports_body

@update_tail