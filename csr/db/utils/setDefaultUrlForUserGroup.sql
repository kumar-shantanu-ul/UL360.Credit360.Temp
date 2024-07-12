DECLARE
	v_host				VARCHAR2(255) := '&&AppName';
	v_group_name			VARCHAR2(255) := '&&GroupName';
	v_url				VARCHAR2(255) := '&&RelativeURL';
BEGIN
	security.user_pkg.LogonAdmin(v_host);
	security.web_pkg.SetHomePage(security_pkg.GetAct(), security_pkg.GetApp(), securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Groups/'||v_group_name), v_url, v_host);
END;
/
