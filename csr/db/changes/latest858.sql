-- Please update version.sql too -- this keeps clean builds in sync
define version=858
@update_header

-- RegisteredUsers need read permission on /fp/shared/extux/upload
declare
	v_reg_users_sid			number;
	v_wwwroot_sid			number;
	v_fp_sid				number;
	v_shared_sid			number;
	v_extux_sid				number;
	v_upload_sid			number;
	v_acl_count				number;
begin
	dbms_output.enable(null);
	security.user_pkg.LogonAdmin;
	for r in (select host, app_sid, system_mail_address
				from csr.customer) loop
		security.security_pkg.SetApp(r.app_sid);

		dbms_output.put_line('doing '||r.host);
		begin
			v_reg_users_sid := security.securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
		exception
			when security.security_pkg.object_not_found then
				dbms_output.put_line('No registered users group');
		end;
		v_wwwroot_sid := security.securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot');
		v_fp_sid := security.securableObject_pkg.getsidfrompath(null, v_wwwroot_sid, 'fp');
		
		begin
			v_shared_sid := security.securableObject_pkg.getsidfrompath(null, v_fp_sid, 'shared');
		exception
			when security.security_pkg.object_not_found then
				security.web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_fp_sid, 'shared', v_shared_sid);
		end;

		begin
			v_extux_sid := security.securableObject_pkg.getsidfrompath(null, v_shared_sid, 'extux');
		exception
			when security.security_pkg.object_not_found then
				security.web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_shared_sid, 'extux', v_extux_sid);
		end;

		begin
			v_upload_sid := security.securableObject_pkg.getsidfrompath(null, v_extux_sid, 'upload');
		exception
			when security.security_pkg.object_not_found then
				security.web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_extux_sid, 'upload', v_upload_sid);
		end;

		security.securableobject_pkg.clearFlag(sys_context('security', 'act'), v_upload_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.DeleteAllAces(sys_context('security', 'act'), security.acl_pkg.GetDACLIDForSID(v_upload_sid));
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_upload_sid), 
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	end loop;
end;
/

@update_tail
