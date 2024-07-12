-- Please update version.sql too -- this keeps clean builds in sync
define version=419
@update_header

-- give registeredusers access to /fp/cms. New sites have this as standard.
declare
	v_wwwroot_sid security_pkg.t_sid_id;
	v_fp_sid security_pkg.t_sid_id;
	v_cms_sid security_pkg.t_sid_id;
	v_admins_sid security_pkg.t_sid_id;
begin
	for r in (select app_sid, host from customer) loop
		begin
			user_pkg.logonadmin(r.host);
			v_admins_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'groups/registeredusers');
			v_wwwroot_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot');
			v_fp_sid := securableObject_pkg.getsidfrompath(null, v_wwwroot_sid, 'fp');
			begin
				v_cms_sid := securableObject_pkg.getsidfrompath(null, v_fp_sid, 'cms');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_fp_sid, 'cms', v_cms_sid);
					acl_pkg.AddACE(sys_context('security', 'act'), acl_pkg.GetDACLIDForSID(v_cms_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
					DBMS_OUTPUT.PUT_LINE('Fixing '||r.host);
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
