-- Please update version.sql too -- this keeps clean builds in sync
define version=1208
@update_header

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT c.host, co.is_value_chain FROM csr.customer c, ct.customer_options co WHERE c.app_sid = co.app_sid
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		chain.capability_pkg.HideCapability(chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE, chain.chain_pkg.ADMIN_GROUP);
		
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_ru_group 					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
			v_hu_group 					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Hotspot Users');
			v_rhu_group 				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Restricted Hotspot Users');
			v_admins_group				security.security_pkg.T_SID_ID;
			v_users_group				security.security_pkg.T_SID_ID;
			v_vca_group 				security.security_pkg.T_SID_ID;
			v_vcu_group 				security.security_pkg.T_SID_ID;
			v_top_company_sid			security.security_pkg.T_SID_ID;
		BEGIN
			-- figure out which company is the top company
			BEGIN
				SELECT company_sid
				  INTO v_top_company_sid
				  FROM chain.company
				 WHERE app_sid = v_app_sid
				   AND company_sid IN (
						SELECT company_sid
						  FROM ct.breakdown
						 WHERE app_sid = v_app_sid
						)
				   AND company_sid NOT IN (
						SELECT company_sid
						  FROM ct.supplier
						 WHERE app_sid = v_app_sid
						   AND company_sid IS NOT NULL
						);
			EXCEPTION WHEN NO_DATA_FOUND THEN
				NULL;
			END;
			
			IF v_top_company_sid IS NOT NULL THEN
				UPDATE chain.customer_options SET top_company_sid = v_top_company_sid WHERE app_sid = v_app_sid;
				
				chain.capability_pkg.SetCapabilityPermission(v_top_company_sid, chain.chain_pkg.USER_GROUP, chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE);
				
				FOR c IN (
					SELECT company_sid FROM chain.company WHERE app_sid = v_app_sid
				) 
				LOOP
				
					v_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, c.company_sid, 'Administrators');
					v_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, c.company_sid, 'Users');
				
					IF r.is_value_chain = 0 THEN
						-- adds hotspot users as admins
						security.group_pkg.AddMember(v_act_id, v_hu_group, v_admins_group);
					ELSE
						-- remove hotspot users from company admins
						security.group_pkg.DeleteMember(v_act_id, v_hu_group, v_admins_group);
						-- remove registeredusers from hotspot users
						security.group_pkg.DeleteMember(v_act_id, v_ru_group, v_hu_group);
												
						IF c.company_sid = v_top_company_sid THEN
							v_vca_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Value Chain Admins');
							v_vcu_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Value Chain Users');
							-- adds value chain [admins/users] as company [admins/users]
							security.group_pkg.AddMember(v_act_id, v_vca_group, v_admins_group);
							security.group_pkg.AddMember(v_act_id, v_vcu_group, v_users_group);
						ELSE
							-- adds company users as restricted hotspotter users
							security.group_pkg.AddMember(v_act_id, v_users_group, v_rhu_group);
						END IF;
					END IF;
				
				END LOOP;
			END IF;			 
		END;		
	END LOOP;
END;
/

GRANT ALL ON CHAIN.CUSTOMER_OPTIONS TO CT;

@..\ct\link_body
@..\ct\util_body

@update_tail
