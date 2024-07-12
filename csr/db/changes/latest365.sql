-- Please update version.sql too -- this keeps clean builds in sync
define version=365
@update_header

-- tidy up useless tree for vancity with missing backing SO
delete from region_tree where region_tree_root_sid = 9193704;
delete from region where region_sid = 9193704;

begin
dbms_output.enable(NULL); -- unlimited output, lovely
end;
/

begin
	for r in (select app_sid, host from customer) loop
		dbms_output.put_line('fixing '||r.host);
		begin
			-- check membership of groups
			user_pkg.logonadmin(r.host);
			for s in (select cu.user_name, isp.ind_sid, isp.user_sid, i.description ind_description
			  			from csr_user cu, ind i, (
							  select ind_sid, user_sid
					  		    from ind_start_point
					  		   where app_sid = r.app_sid
					  		   minus
					  		  select group_sid_id, member_sid_id
					  		    from security.group_members) isp
					   where cu.csr_user_sid = isp.user_sid and cu.app_sid = r.app_sid and
					   		 i.app_sid = r.app_sid and i.ind_sid = isp.ind_sid and
					   		 isp.user_sid not in (3,5) /* skip builtin/guest, builtin/admin */ and
					   		 isp.user_sid not in (select csr_user_sid from superadmin) /* skip superadmins */) loop
				dbms_output.put_line('user '||s.user_sid||' ('||s.user_name||') is not a member of '||s.ind_sid||' ('||s.ind_description||')');
				insert into security.group_members 
					(group_sid_id, member_sid_id)
				values
					(s.ind_sid, s.user_sid);
			end loop;
			-- check acl to make sure each ind includes read permissions on itself
			for s in (select i.ind_sid, a.sid_id, a.permission_set
					    from ind i
					  	     left outer join security.securable_object so
					  	     on i.ind_sid = so.sid_id 
					  	     left outer join security.acl a
					  	     on so.dacl_id = a.acl_id and i.ind_sid = a.sid_id and a.permission_set = 225
					   where a.sid_id is null) loop
				-- add object to the DACL (the ind is a group, so it has permissions on itself)
				dbms_output.put_line('indicator '||s.ind_sid||' is missing self read permissions');
				acl_pkg.AddACE(sys_context('security', 'act'), 
					acl_pkg.GetDACLIDForSID(s.ind_sid), 
					security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, s.ind_sid, security_pkg.PERMISSION_STANDARD_READ);
				acl_pkg.PropogateACEs(sys_context('security', 'act'), s.ind_sid);
			end loop;			
			-- check membership of groups
			for s in (select cu.user_name, rsp.region_sid, rsp.user_sid, r.description region_description
			  			from csr_user cu, region r, (
							  select region_mount_point_sid region_sid, csr_user_sid user_sid
					  		    from csr_user
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
					  	     left outer join security.securable_object so
					  	     on r.region_sid = so.sid_id 
					  	     left outer join security.acl a
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

@../region_body

@update_tail
