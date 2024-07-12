PROMPT Enter host

declare	
	-- group to role stuff
	TYPE T_ROLE_NAMES IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_role_names			T_ROLE_NAMES;
	v_role_sid				security.security_pkg.T_SID_ID;
	-- misc
	v_act					security.security_pkg.T_ACT_ID;
	v_app					security.security_pkg.T_SID_ID;
	-- region permissions
	v_user_group_sid		security.security_pkg.T_SID_ID;
begin
	security.user_pkg.logonadmin('&&1');
	
	v_act := security.security_pkg.getACT;
	v_app := security.security_pkg.getApp;
	
	-- convert a couple of standard groups to roles as it's useful for the workflows
	v_role_names(1) := 'Suppliers';
	FOR i IN v_role_names.FIRST..v_role_names.LAST
	LOOP	
		UPDATE csr.role
		   SET name = v_role_names(i)
		 WHERE LOWER(name) = LOWER(v_role_names(i))
		   AND app_sid = v_app
		 RETURNING role_sid INTO v_role_sid;

		IF SQL%ROWCOUNT = 0 THEN
			v_role_sid := security.securableobject_pkg.getSidFromPath(v_act, v_app, 'Groups/'||v_role_names(i));
			
			UPDATE security.securable_object
			   SET class_id = security.class_pkg.GetClassId('CSRRole')
			 WHERE sid_id = v_role_sid;

			INSERT INTO csr.role (role_sid, app_sid, name, IS_PROPERTY_MANAGER, is_supplier) 
				VALUES (v_role_sid, v_app, v_role_names(i), 1, 1);
		END IF;
	END LOOP;

	-- now put the users in the right roles
	INSERT INTO region_role_member (role_sid, user_sid, region_sid, inherited_from_sid)
		select csr.role_pkg.GetRoleId(v_app, 'Suppliers'), cu.user_sid, s.region_sid, s.region_sid
		  from chain.v$company_user cu
		  join csr.supplier s on cu.company_sid = s.supplier_sid
		 WHERE cu.company_sid NOT IN (select top_company_sid from chain.customer_options)
		   AND (s.region_sid, cu.user_sid) NOT IN (
			SELECT region_sid, user_sid
			  FROM region_role_member
			 WHERE role_sid = csr.role_pkg.GetRoleId(v_app, 'Suppliers')
			);
	
	-- Grant permissions on regions for property manager to work
	FOR r IN (
		SELECT c.company_sid, s.region_sid
		  FROM chain.company c
		  JOIN csr.supplier s ON c.company_sid = s.supplier_sid
	) LOOP
		v_user_group_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, r.company_sid, 'Users');
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(r.region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_group_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;
/

exit
