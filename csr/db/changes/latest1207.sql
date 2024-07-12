-- Please update version.sql too -- this keeps clean builds in sync
define version=1207
@update_header

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT c.host, co.is_value_chain FROM csr.customer c, ct.customer_options co WHERE c.app_sid = co.app_sid
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		security.group_pkg.AddMember(security.security_pkg.GetAct, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/RegisteredUsers'), security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Hotspot Users'));		
		security.acl_pkg.PropogateACEs(security.security_pkg.GetAct, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot/csr/site/ct'));
		security.acl_pkg.PropogateACEs(security.security_pkg.GetAct, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'menu/hotspot_dashboard'));
	END LOOP;
END;
/

@..\ct\supplier_pkg
@..\ct\supplier_body

@update_tail
