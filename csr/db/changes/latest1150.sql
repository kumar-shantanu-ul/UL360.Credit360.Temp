-- Please update version.sql too -- this keeps clean builds in sync
define version=1150
@update_header

-- Grants UserCreatorDaemon permissions on Delegations so that it can be used as an elevated user
-- when regions are modified that affect delegation plans

DECLARE
	v_act						security.security_pkg.T_ACT_ID;
	v_user_creator_daemon_sid	security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
	v_acl_count					NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	
	v_act := security.security_pkg.getAct;
	
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
	) LOOP
		BEGIN
			
			v_user_creator_daemon_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Users/UserCreatorDaemon');
			
			BEGIN
				v_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Delegations');
				
				SELECT COUNT(*)
				INTO v_acl_count
				FROM security.acl 
				WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_sid)
				AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
				AND sid_id = v_user_creator_daemon_sid
				AND permission_set = security.security_pkg.PERMISSION_STANDARD_ALL + csr.csr_data_pkg.PERMISSION_ALTER_SCHEMA;
				
				IF v_acl_count = 0 AND security.acl_pkg.GetDACLIDForSID(v_sid) IS NOT NULL THEN
					-- Grant UserCreatorDaemon all permissions on delegations for when delegation plans roll out
					security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security.security_pkg.PERMISSION_STANDARD_ALL + csr.csr_data_pkg.PERMISSION_ALTER_SCHEMA);
					security.acl_pkg.PropogateACEs(v_act, v_sid);
				END IF;
				
			EXCEPTION
				WHEN security.security_pkg.object_not_found THEN NULL;
			END;
			
			BEGIN
				v_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'DelegationPlans');
				SELECT COUNT(*)
				INTO v_acl_count
				FROM security.acl 
				WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_sid)
				AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
				AND sid_id = v_user_creator_daemon_sid
				AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
				
				IF v_acl_count = 0 AND security.acl_pkg.GetDACLIDForSID(v_sid) IS NOT NULL THEN
					-- Grant UserCreatorDaemon all permissions on delegations for when delegation plans roll out
					security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					
					security.acl_pkg.PropogateACEs(v_act, v_sid);
				END IF;
			EXCEPTION
				WHEN security.security_pkg.object_not_found THEN NULL;
			END;
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN NULL;
		END;
			
		COMMIT; -- commit per site as its likely to take a while
		
	END LOOP;

END;
/

@update_tail
