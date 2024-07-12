-- Please update version.sql too -- this keeps clean builds in sync
define version=2384
@update_header

-- copy permissions from userSettings.acds to new userSettings.js file
DECLARE
	v_new_www_sid           security.security_pkg.T_SID_ID;
    v_www_csr_site			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin;
	FOR rr IN (
		select web_root_sid_id, sid_id from security.web_resource where path = '/csr/site/userSettings.acds'
	)
	LOOP
		dbms_output.put_line('fixing '||rr.sid_id);
		v_www_csr_site := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, rr.web_root_Sid_id, 'csr/site');
		BEGIN
			security.web_pkg.CreateResource(security.security_pkg.getact, rr.web_root_Sid_id, v_www_csr_site, 'userSettings.js', v_new_www_sid);
			
			security.acl_pkg.DeleteAllACEs(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_new_www_sid));
			FOR r IN (
				SELECT a.acl_id, a.acl_index, a.ace_type, a.ace_flags, a.permission_set, a.sid_id
				  FROM security.securable_object so
				  JOIN security.acl a ON so.dacl_id = a.acl_id
				 WHERE so.sid_id = rr.sid_id
				 ORDER BY acl_index      
			)
			LOOP
				security.acl_pkg.AddACE(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_new_www_sid), r.acl_index, 
					r.ace_type, r.ace_flags, r.sid_id, r.permission_Set);
			END LOOP;
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail