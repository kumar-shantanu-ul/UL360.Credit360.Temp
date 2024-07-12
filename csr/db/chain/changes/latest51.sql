define version=51
@update_header

DECLARE
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_respondant			security_pkg.T_SID_ID;
	v_count		NUMBER(10);
BEGIN
	FOR r IN (
		SELECT c.host FROM customer_options co, csr.customer c WHERE c.app_sid = co.app_sid
	) LOOP

		user_pkg.LogonAdmin(r.host);
		v_act_id := security_pkg.GetAct;
		v_app_sid := security_pkg.GetApp;
		
		v_respondant := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain/BuiltIn/Invitation Respondent');
		
		
		-- this is required for accepting and rejecting invitations
		FOR s IN (
			SELECT 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users') on_sid, 
					security_pkg.SID_BUILTIN_ADMINISTRATOR to_sid
			  FROM DUAL
			 UNION ALL
			SELECT 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Trash') on_sid, 
					security_pkg.SID_BUILTIN_ADMINISTRATOR to_sid
			  FROM DUAL
			 UNION ALL
			SELECT 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users') on_sid, 
					v_respondant to_sid 
			  FROM DUAL
		) LOOP
		
			SELECT COUNT(*)
			  INTO v_count
			  FROM security.acl 
			 WHERE acl_id = acl_pkg.GetDACLIDForSID(s.on_sid)
			   AND sid_id = s.to_sid
			   AND permission_set = security_pkg.PERMISSION_STANDARD_ALL;

			IF v_count = 0 THEN
				acl_pkg.AddACE(
					v_act_id, 
					acl_pkg.GetDACLIDForSID(s.on_sid), 
					security_pkg.ACL_INDEX_LAST, 
					security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_DEFAULT, 
					s.to_sid, 
					security_pkg.PERMISSION_STANDARD_ALL
				);	

				acl_pkg.PropogateACEs(v_act_id, s.on_sid);
			END IF;
		END LOOP;
		
		-- we need to stuff this user into the csr user table so that we can use it within chain as well
		BEGIN
			INSERT INTO csr.csr_user
			(csr_user_sid, guid, user_name, friendly_name, send_alerts, show_portal_help, hidden)
			VALUES
			(v_respondant, user_pkg.GenerateAct, 'Invitation Respondent', 'Chain Invitation Respondent', 0, 0, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		chain_pkg.AddUserToChain(v_respondant);
		
	END LOOP;	
END;
/

@..\invitation_pkg
@..\invitation_body

@update_tail

