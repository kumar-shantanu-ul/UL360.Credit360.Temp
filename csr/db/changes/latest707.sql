-- Please update version.sql too -- this keeps clean builds in sync
define version=707
@update_header

BEGIN
	INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage emission factors', 0);
	commit;
END;
/

declare
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
begin	
	user_pkg.logonadmin;
	for r in (select app_sid from customer where use_carbon_emission=1) loop
		security_pkg.setapp(r.app_sid);
	    -- just create a sec obj of the right type in the right place
	    BEGIN
			v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
	        v_capabilities_sid, 
	        class_pkg.GetClassId('CSRCapability'),
	        'Manage emission factors',
	        v_capability_sid
	    );
	end loop;
end;
/

declare
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
	v_carbon_admins_sid		security_pkg.T_SID_ID;
begin	
	user_pkg.logonadmin;
	for r in (select app_sid, host from csr.customer where use_carbon_emission=1) loop
		security_pkg.setapp(r.app_sid);
		v_capability_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Manage emission factors');
		
		BEGIN
			v_carbon_admins_sid := securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Groups/Emission factor Admins');
			acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(v_capability_sid), -1,
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_carbon_admins_sid,
				security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line('skipping granting capability to Emission factor Admins group for ' ||r.host||' ('||r.app_sid||') as the group is missing');		
		END;
	end loop;
end;
/

@update_tail
