-- Please update version.sql too -- this keeps clean builds in sync
define version=1409
@update_header

-- based on latest1299

BEGIN
	security.user_pkg.Logonadmin();

	FOR r in (
		SELECT c.host
		  FROM csr.customer c
	)
	LOOP
		BEGIN
			security.user_pkg.Logonadmin(r.host);

			DECLARE
				v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
				v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
				v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
				v_registered_users_sid		security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
				v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
				v_csr_site_exists			NUMBER(1);
				v_csr_site_sid				security.security_pkg.T_SID_ID;
				v_site_indicatorsets_sid	security.security_pkg.T_SID_ID;
			BEGIN
				BEGIN
					v_csr_site_exists := 0;
					v_csr_site_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
					v_csr_site_exists := 1;
					v_site_indicatorsets_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_sid, 'indicatorSets');
				EXCEPTION 
					WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
						IF v_csr_site_exists = 1 THEN
							security.web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_sid, 'indicatorSets', v_site_indicatorsets_sid);

							-- as well as inheriting the dacls from csr/site,
							-- give the RegisteredUsers group READ permission on the resource
							security.acl_pkg.AddACE(
								v_act_id,
								security.Acl_pkg.GetDACLIDForSID(v_site_indicatorsets_sid),
								security.security_pkg.ACL_INDEX_LAST,
								security.security_pkg.ACE_TYPE_ALLOW,
								security.security_pkg.ACE_FLAG_DEFAULT,
								v_registered_users_sid,
								security.security_pkg.PERMISSION_STANDARD_READ);
						END IF;
				END;
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;

	security.user_pkg.Logonadmin();
END;
/

@update_tail
