
PROMPT please enter: host

DECLARE
	v_count		NUMBER(10);
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	FOR r in (SELECT * FROM csr.region WHERE link_to_region_sid IS NOT NULL) LOOP
		
		FOR p in (SELECT * FROM csr.region pr START WITH pr.region_Sid = r.region_sid CONNECT BY PRIOR parent_sid = region_sid) LOOP
		
			SELECT count(*)
			  INTO v_count
			  FROM security.securable_object so
			  JOIN security.acl a ON so.dacl_id = a.acl_id
			 WHERE so.sid_id = r.link_to_region_sid
			   AND a.sid_id = p.region_sid;
			
			IF v_count = 0 THEN
				acl_pkg.AddACE(sys_context('security', 'act'), 
					acl_pkg.GetDACLIDForSID(r.link_to_region_sid), 
					security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, p.region_sid, security_pkg.PERMISSION_STANDARD_READ);
				acl_pkg.PropogateACEs(sys_context('security', 'act'), r.link_to_region_sid);
			END IF;
			
		END LOOP;
		
	END LOOP;
END;
/