-- Please update version.sql too -- this keeps clean builds in sync
define version=398
@update_header

declare
	v_wwwroot_sid security_pkg.t_sid_id;
	v_fp_sid security_pkg.t_sid_id;
	v_yam_sid security_pkg.t_sid_id;
	v_admins_sid security_pkg.t_sid_id;
begin
	for r in (select app_sid, host from customer) loop
		begin
			user_pkg.logonadmin(r.host);
			v_admins_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'groups/administrators');
			v_wwwroot_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot');
			v_fp_sid := securableObject_pkg.getsidfrompath(null, v_wwwroot_sid, 'fp');
			begin
				v_yam_sid := securableObject_pkg.getsidfrompath(null, v_fp_sid, 'yam');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_fp_sid, 'yam', v_yam_sid);
					acl_pkg.AddACE(sys_context('security', 'act'), acl_pkg.GetDACLIDForSID(v_yam_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
			end;
			security_pkg.setApp(null);
		exception
			when security_pkg.object_not_found then
				null; -- customers that have no sites
		end;
	end loop;
end;
/

@update_tail
