-- Please update version.sql too -- this keeps clean builds in sync
define version=1930
@update_header

DECLARE
	v_issues_sid 				security.security_pkg.T_SID_ID;
	v_www_sid 					security.security_pkg.T_SID_ID;
	v_www_csr_site 				security.security_pkg.T_SID_ID;
	v_registeredUsers_sid		security.security_pkg.T_SID_ID;
BEGIN

	FOR r IN (
		SELECT c.host
		  FROM cms.tab t
		  JOIN csr.customer c
		    ON c.app_sid = t.app_sid
		 WHERE t.oracle_schema = 'CSR' and t.oracle_table='ISSUE'
		  
	) LOOP
		security.user_pkg.logonadmin(r.host);
	
		BEGIN
			v_issues_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'wwwroot/csr/site/issues');
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN
				v_www_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot');
				v_www_csr_site := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, v_www_sid, 'csr/site');
				security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_sid, v_www_csr_site, 'issues', v_issues_sid);
		END;
		
		v_registeredUsers_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers');
		

		security.acl_pkg.RemoveACEsForSid(security.security_pkg.getAct,
			security.acl_pkg.GetDACLIDForSID(v_issues_sid),
			v_registeredUsers_sid);
		
		security.acl_pkg.AddACE(security.security_pkg.getAct, 
				security.acl_pkg.GetDACLIDForSID(v_issues_sid),
				-1,
				security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_registeredUsers_sid,
				security.security_pkg.PERMISSION_STANDARD_READ);	
		
		security.acl_pkg.PropogateACEs(security.security_pkg.getAct, v_issues_sid);	
		
	END LOOP;
END;
/


@update_tail
