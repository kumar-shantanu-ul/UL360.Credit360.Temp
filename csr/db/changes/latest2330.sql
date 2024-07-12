-- Please update version.sql too -- this keeps clean builds in sync
define version=2330
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Choose new property parent', 0);

DECLARE
	v_capabilities_sid		security.security_pkg.T_SID_ID;
	v_capability_sid		security.security_pkg.T_SID_ID;
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

	END LOOP;

	COMMIT;
END;
/

@update_tail
