-- Please update version.sql too -- this keeps clean builds in sync
define version=50
@update_header


UPDATE sheet_action_permission SET can_save =1, can_submit = 1 WHERE user_level =2 AND sheet_action_id = 6

commit;

-- make sure public web resource exists
DECLARE
	v_act 	security_pkg.T_ACT_ID;
	v_wwwroot 	security_pkg.T_SID_ID;
	v_csr 	security_pkg.T_SID_ID;
	v_public 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN (
		SELECT so.parent_sid_id app_sid
		  FROM customer c, SECURITY.securable_object so
		 WHERE c.csr_root_Sid = so.sid_id
    ) LOOP
    	v_wwwroot := securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'wwwroot');
        -- csr/public
        v_csr := securableobject_pkg.GetSIDFromPath(v_act, v_wwwroot, 'csr');
        BEGIN
	        v_public := securableobject_pkg.GetSIDFromPath(v_act, v_csr, 'public');
        EXCEPTION
        	WHEN Security_Pkg.OBJECT_NOT_FOUND THEN
				web_pkg.CreateResource(v_act, v_wwwroot, v_csr, 'public', v_public);
				acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_public), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);          		       
        END;
	END LOOP;
END;
/
commit;
/

@update_tail
