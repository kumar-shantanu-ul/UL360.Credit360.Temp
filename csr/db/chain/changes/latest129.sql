define version=129
@update_header

DECLARE
	v_chain_managers_sid		security_pkg.T_SID_ID;
	
BEGIN
	FOR r IN (
		SELECT host
		  FROM chain.v$chain_host
		 WHERE chain_implementation LIKE 'CSR.%'
	)
	LOOP
		user_pkg.LogonAdmin(r.host);
		
		BEGIN
			v_chain_managers_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.GetApp, 'Groups/Supply Chain Managers');
		EXCEPTION WHEN security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(
				security_pkg.getACT,
				securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups'),
				security_pkg.GROUP_TYPE_SECURITY,
				'Supply Chain Managers',
				v_chain_managers_sid
				);
		END;
		
	END LOOP;
END;
/



@update_tail
