
PROMPT Enter the host name
set serveroutput on;
declare
	v_host				VARCHAR2(255) := '&&1';
	v_sso_users_group_name		VARCHAR2(1024) := 'SSO Users';
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_sso_users_group_sid		security.security_pkg.T_SID_ID;
begin
	security.user_pkg.LogonAdmin(v_host);

	v_groups_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Groups');
	
	begin
		v_sso_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_sso_users_group_name);
		dbms_output.put_line('"' || v_sso_users_group_name || '" group (#' || v_sso_users_group_sid || ') found.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, v_sso_users_group_name, security.class_pkg.GetClassID('CSRUserGroup'), v_sso_users_group_sid);
			dbms_output.put_line('"' || v_sso_users_group_name || '" group not found. Created one. (#' || v_sso_users_group_sid || ')');
	end;
end;
/

