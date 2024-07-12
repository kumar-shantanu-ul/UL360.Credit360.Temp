-- Please update version.sql too -- this keeps clean builds in sync
define version=412
@update_header

set serveroutput on
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
			v_yam_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot/fp/yam');
			UPDATE security.acl
			   SET ace_flags = security_pkg.ACE_FLAG_INHERITABLE+security_pkg.ACE_FLAG_INHERIT_INHERITABLE
			 WHERE acl_id = acl_pkg.GetDACLIDForSID(v_yam_sid)
			   AND bitand(ace_flags, security_pkg.ACE_FLAG_INHERITABLE+security_pkg.ACE_FLAG_INHERIT_INHERITABLE) != security_pkg.ACE_FLAG_INHERITABLE+security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
			if sql%rowcount = 0 then
				dbms_output.put_line('ok: '||r.host);
			else
				dbms_output.put_line('fixed: '||r.host);
			end if;
			security_pkg.setApp(null);
		exception
			when security_pkg.object_not_found then
				null; -- customers that have no sites
		end;
	end loop;
end;
/

@update_tail
