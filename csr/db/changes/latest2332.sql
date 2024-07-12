-- Please update version.sql too -- this keeps clean builds in sync
define version=2332
@update_header

DECLARE
	v_capabilities_sid		security.security_pkg.T_SID_ID;
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_administrators_sid	security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT host FROM csr.customer WHERE property_flow_sid IS NOT NULL
	) LOOP

		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
	
		BEGIN
			v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), v_capabilities_sid, 'Choose new property parent');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					v_capabilities_sid, 
					security.class_pkg.GetClassId('CSRCapability'),
					'Choose new property parent',
					v_capability_sid
				);
		END;
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(security.security_pkg.GetAct, v_capability_sid, 0);
		-- clean existing ACE's
		security.acl_pkg.DeleteAllACEs(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_capability_sid));

		-- admins can read and change
		BEGIN
			v_administrators_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Administrators');

			security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.Acl_pkg.GetDACLIDForSID(v_capability_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				0, v_administrators_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_READ_PERMISSIONS + security.security_pkg.PERMISSION_CHANGE_PERMISSIONS);	

		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;


	END LOOP;

	COMMIT;
END;
/

@update_tail
