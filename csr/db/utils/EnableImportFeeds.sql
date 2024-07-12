prompt Enter host: 
define host="&&1"

declare
	v_act				security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	v_import_feeds_sid	security.security_pkg.T_SID_ID;
begin
	security.user_pkg.LogonAdmin('&&host');
	
	v_act := security.security_pkg.GetACT;
	v_app_sid := security.security_pkg.GetApp;

	begin
		security.securableobject_pkg.CreateSO(v_act, v_app_sid, security.security_pkg.SO_CONTAINER, 'ImportFeeds', v_import_feeds_sid);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_import_feeds_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'ImportFeeds');
	end;
end;
/
