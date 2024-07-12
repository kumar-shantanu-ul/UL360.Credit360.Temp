-- Please update version.sql too -- this keeps clean builds in sync
define version=1590
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit region active', 0);
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit region categories', 0);

DECLARE
	v_sa_sid					security.security_pkg.T_SID_ID;
	v_capability_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	v_sa_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	
	FOR r IN (
		SELECT host FROM csr.customer WHERE host IN ('spm.credit360.com', 'spm.uat.credit360.com')
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		BEGIN
			csr.csr_data_pkg.EnableCapability('Edit region active', 0);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		v_capability_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Edit region active');
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(security.security_pkg.GetAct, v_capability_sid, 0);
		-- clean existing ACE's
		security.acl_pkg.DeleteAllACEs(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_capability_sid));
				
		security.acl_pkg.AddACE(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_capability_sid), 
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		
		BEGIN
			csr.csr_data_pkg.EnableCapability('Edit region categories', 0);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		v_capability_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Edit region categories');
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(security.security_pkg.GetAct, v_capability_sid, 0);
		-- clean existing ACE's
		security.acl_pkg.DeleteAllACEs(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_capability_sid));
				
		security.acl_pkg.AddACE(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_capability_sid), 
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;
/

@..\region_pkg
@..\region_body

@..\tag_body

@update_tail