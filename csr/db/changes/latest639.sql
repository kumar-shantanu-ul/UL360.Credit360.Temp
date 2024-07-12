-- Please update version.sql too -- this keeps clean builds in sync
define version=639
@update_header

SET SERVEROUTPUT ON

-- Allow super admins to control gauge-style charts for all current applications.

DECLARE
	v_capability VARCHAR2(2000) := 'Use gauge-style charts';

	v_act security.security_pkg.T_ACT_ID;
	v_capabilities_sid security.security_pkg.T_ACT_ID;
	v_capability_sid security.security_pkg.T_ACT_ID;
	v_superadmin_group_sid security.security_pkg.T_ACT_ID;
BEGIN	
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	v_superadmin_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, '/CSR/SuperAdmins');

	FOR r IN (SELECT app_sid, host FROM csr.customer)
	LOOP
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Capabilities');
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN
				v_capabilities_sid := NULL;
		END;

		IF v_capabilities_sid IS NOT NULL THEN
			BEGIN
				v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_capabilities_sid, v_capability);
			EXCEPTION
				WHEN security.security_pkg.object_not_found THEN
					security.securableobject_pkg.CreateSO(v_act, v_capabilities_sid, security.class_pkg.GetClassId('CSRCapability'), v_capability, v_capability_sid);
					security.securableobject_pkg.ClearFlag(v_act, v_capability_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.DeleteAllACES(v_act, security.acl_pkg.GetDACLIDForSID(v_capability_sid));
			END;

			dbms_output.put_line('Processing ' || r.host);
			
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_capability_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_READ_PERMISSIONS + security.security_pkg.PERMISSION_CHANGE_PERMISSIONS);
		END IF;
	END LOOP;
END;
/

@update_tail
