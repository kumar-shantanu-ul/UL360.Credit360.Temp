CREATE OR REPLACE PACKAGE csr.fb63250_pkg IS

PROCEDURE AddCmsPermission(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_permission_name		IN  security.Security_pkg.T_PERMISSION_NAME
);

PROCEDURE AddToCmsContainer(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_cms_container_so		IN	security.Security_pkg.T_SID_ID
);

PROCEDURE AddToCmsTables(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_cms_container_so		IN	security.Security_pkg.T_SID_ID
);

END;
/

CREATE OR REPLACE PACKAGE BODY csr.fb63250_pkg IS

-- Fails if the permission (number) is already taken for CmsTable or CmsContainer Class
PROCEDURE AddCmsPermission(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_permission_name		IN  security.Security_pkg.T_PERMISSION_NAME
)
AS
	v_check		NUMBER(1);
	v_act       security.security_pkg.T_ACT_ID;
BEGIN
	v_act := security.Security_pkg.GetAct;

	SELECT COUNT(*) INTO v_check
	  FROM  security.permission_name
	 WHERE class_id = security.class_pkg.GetClassId('CMSTable')
	   AND permission = in_permission
	   AND permission_name = in_permission_name;
	   
	IF v_check = 0 THEN
		security.class_pkg.AddPermission(v_act, security.class_pkg.GetClassId('CMSTable'), in_permission, in_permission_name);
	END IF;
	
	SELECT COUNT(*) INTO v_check
	  FROM  security.permission_name
	 WHERE class_id = security.class_pkg.GetClassId('CMSContainer')
	   AND permission = in_permission
	   AND permission_name = in_permission_name;
	   
	IF v_check = 0 THEN
		security.class_pkg.AddPermission(v_act, security.class_pkg.GetClassId('CMSContainer'), in_permission, in_permission_name);
	END IF;

END;

PROCEDURE AddToCmsContainer(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_cms_container_so		IN	security.Security_pkg.T_SID_ID
)
AS
BEGIN
	-- For each group with read permission on , grant new permission as well.
	FOR n IN (
		 SELECT a.acl_id, 
				a.acl_index,
				a.ace_type, 
				a.ace_flags,
				a.sid_id, 
				a.permission_set, 
				so.name, 
				soc.class_name
		   FROM security.ACL a
		   JOIN security.securable_object so ON a.sid_id = so.sid_id
		   JOIN security.securable_object_class soc ON so.class_id = soc.class_id
		  WHERE a.acl_id = security.acl_pkg.GetDACLIDForSID(in_cms_container_so)		-- <= object sid
		    AND so.application_sid_id = security.Security_pkg.GetApp					-- safeguard
			AND so.sid_id NOT IN (security.security_pkg.SID_BUILTIN_ADMINISTRATOR, security.security_pkg.SID_BUILTIN_ADMINISTRATORS) --  Leave these alone!!
			AND bitand(a.permission_set, security.Security_pkg.PERMISSION_READ) != 0	-- Has read permission 
			AND bitand(a.permission_set, in_permission) = 0								-- Doesn't have new permission already
			AND bitand(a.ace_flags, security.Security_pkg.ACE_FLAG_INHERITED) = 0		-- Isn't inherited. This is set from CmsContainer.
	   ORDER BY a.acl_index
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('UPDATE ACL on CMS Container for '||n.name);
		UPDATE security.ACL
		   SET permission_set = security.Bitwise_Pkg.bitor(permission_set, in_permission)
		 WHERE acl_id = n.acl_id
		   AND acl_index = n.acl_index;
	END LOOP;
	
END;

-- Safely repeatable. It updates the ACL with new permission but won't do it if called again
PROCEDURE AddToCmsTables(
	in_permission			IN  security.Security_pkg.T_PERMISSION,
	in_cms_container_so		IN	security.Security_pkg.T_SID_ID
)
AS
BEGIN
	FOR t IN (
		 SELECT so.sid_id table_sid,
				so.dacl_id, 
				so.name,
				a.acl_id,
				a.acl_index,
				a.ace_type,
				a.ace_flags,
				a.sid_id,
				a.permission_set,
				gso.name group_name
		   FROM security.securable_object so
		   JOIN security.ACL a ON so.dacl_id = a.acl_id
		   JOIN security.securable_object gso ON a.sid_id = gso.sid_id
		  WHERE so.parent_sid_id = in_cms_container_so
			AND so.application_sid_id = SYS_CONTEXT('security', 'APP')
		    AND so.class_id = security.Class_pkg.GetClassId('CmsTable')
		    AND a.sid_id NOT IN (security.security_pkg.SID_BUILTIN_ADMINISTRATOR, security.security_pkg.SID_BUILTIN_ADMINISTRATORS)  -- Leave these alone
		    AND bitand(a.permission_set, security.Security_pkg.PERMISSION_READ) != 0	-- Has PERMISSION_READ  
		    AND bitand(a.permission_set, in_permission) = 0								-- Doesn't have new permission already
		    AND bitand(a.ace_flags, security.Security_pkg.ACE_FLAG_INHERITED) = 0		-- Isn't inherited. This is set from CmsContainer
	   ORDER BY so.name, a.acl_id, a.acl_index
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('UPDATE ACL on CMS Table ' || t.name || ' for ' || t.group_name);
		UPDATE security.ACL
		   SET permission_set = security.Bitwise_Pkg.bitor(permission_set, in_permission)
		 WHERE acl_id = t.acl_id
		   AND acl_index = t.acl_index;
	END LOOP;
END;

END;
/
