set serveroutput on
begin
	for r in (select app_sid, host from customer) loop
		dbms_output.put_line('fixing '||r.host);
		begin
			user_pkg.logonadmin(r.host);
			-- check membership of groups
			for s in (select cu.user_name, rsp.region_sid, rsp.user_sid, r.description region_description
			  			from csr_user cu, region r, (
							  select region_sid, user_sid
					  		    from region_start_point
					  		   where app_sid = r.app_sid
					  		   minus
					  		  select group_sid_id, member_sid_id
					  		    from security.group_members) rsp
					   where cu.csr_user_sid = rsp.user_sid and cu.app_sid = r.app_sid and
					   		 r.app_sid = r.app_sid and r.region_sid = rsp.region_sid and
					   		 rsp.user_sid not in (3,5) /* skip builtin/guest, builtin/admin */ and
					   		 rsp.user_sid not in (select csr_user_sid from superadmin) /* skip superadmins */) loop
				dbms_output.put_line('user '||s.user_sid||' ('||s.user_name||') is not a member of '||s.region_sid||' ('||s.region_description||')');
				insert into security.group_members 
					(group_sid_id, member_sid_id)
				values
					(s.region_sid, s.user_sid);
			end loop;
			-- check acl to make sure each region includes read permissions on itself
			for s in (select r.region_sid, a.sid_id, a.permission_set
					    from region r
					  	     left join security.securable_object so
					  	     on r.region_sid = so.sid_id 
					  	     left join security.acl a
					  	     on so.dacl_id = a.acl_id and r.region_sid = a.sid_id and a.permission_set = 225
					   where a.sid_id is null) loop
				-- add object to the DACL (the region is a group, so it has permissions on itself)
				dbms_output.put_line('region '||s.region_sid||' is missing self read permissions');
				acl_pkg.AddACE(sys_context('security', 'act'), 
					acl_pkg.GetDACLIDForSID(s.region_sid), 
					security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, s.region_sid, security_pkg.PERMISSION_STANDARD_READ);
				acl_pkg.PropogateACEs(sys_context('security', 'act'), s.region_sid);
			end loop;
			security_pkg.setapp(null);
		exception
			when security_pkg.object_not_found then
				dbms_output.put_line(r.host||' not found!');
		end;
	end loop;
end;
/
