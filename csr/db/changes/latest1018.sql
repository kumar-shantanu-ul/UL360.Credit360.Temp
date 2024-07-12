-- Please update version.sql too -- this keeps clean builds in sync
define version=1018
@update_header

declare
	v_wwwroot_sid	security.security_pkg.t_sid_id;
	v_csr_site_sid	security.security_pkg.t_sid_id;
	v_issues2_sid	security.security_pkg.t_sid_id;
	v_group_sid 	security.security_pkg.t_sid_id;
	
	type t_groups is table of varchar2(255);
	v_groups t_groups;
begin	
	v_groups := t_groups('Administrators', 'Data Providers', 'Data Approvers', 'Auditors');
	
	for r in (select app_sid, host from csr.customer) loop
		begin
			security.user_pkg.logonadmin(r.host);
			dbms_output.put_line('doing '||r.host);
			
			v_wwwroot_sid := security.securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot');
			v_csr_site_sid := security.securableObject_pkg.getsidfrompath(null, v_wwwroot_sid, 'csr/site');
			begin
				security.web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_csr_site_sid, 'issues2', v_issues2_sid);
			exception
				when security.security_pkg.duplicate_object_name then
					dbms_output.put_line('issues2 already exists');
					v_issues2_sid := null;
			end;
			
			if v_issues2_sid is not null then
				for i in 1 .. v_groups.count loop
					begin			
						v_group_sid := security.securableObject_pkg.getsidfrompath(null, r.app_sid, 'groups/'||v_groups(i));
					exception
						when security.security_pkg.object_not_found then
							dbms_output.put_line('groups/'||v_groups(i)||' is missing');
							v_group_sid := null;
					end;
					if v_group_sid is not null then
						security.acl_pkg.AddACE(sys_context('security', 'act'), security.acl_pkg.GetDACLIDForSID(v_issues2_sid), 
							security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
							security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					end if;
				end loop;
			end if;

			security.security_pkg.setApp(null);
		exception
			when security.security_pkg.object_not_found then
				dbms_output.put_line('site so not found'); -- customers that have no sites
		end;
	end loop;
end;
/

@update_tail
