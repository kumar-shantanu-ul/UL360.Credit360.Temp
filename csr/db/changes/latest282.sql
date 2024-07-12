-- Please update version.sql too -- this keeps clean builds in sync
define version=282
@update_header

-- for some reason these aren't in there. 
insert into security.group_members (group_sid_id, member_sid_id)
	select ind_root_sid, ind_root_sid 
	  from customer c, security.group_members gm 
	 where c.ind_root_sid = gm.group_sid_id(+) 
	   and gm.group_sid_id is null;		

insert into security.group_members (group_sid_id, member_sid_id)
	select region_root_sid, region_root_sid 
	  from customer c, security.group_members gm 
	 where c.region_root_sid = gm.group_sid_id(+) 
	   and gm.group_sid_id is null;
	   	 
-- fix up security group things
declare
	v_cnt number(10);
begin
	for r in (
		select distinct user_sid, ind_sid, cu.full_name||' - '||c.host label
		  from ind_start_point isp, csr_user cu, customer c
		 where isp.user_sid =cu.csr_user_sid and isp.app_sid = cu.app_sid and cu.app_sid =c.app_sid
		   AND cu.full_name not in ('User Creator','Builtin Administrator','Guest')
	)
	loop
		SELECT COUNT(*) 
		INTO v_cnt
		  FROM (
			SELECT acl.sid_id
			  FROM security.securable_object so, security.acl 
			 WHERE so.sid_id = r.ind_sid
			   AND so.dacl_id = acl.acl_id   
			 INTERSECT
			SELECT sid_id
			   FROM security.securable_object 
			  WHERE sid_id IN (
				SELECT group_sid_id 
				  FROM security.group_members
				 START WITH member_sid_id = r.user_sid
			   CONNECT BY nocycle prior group_sid_id = member_sid_id
			 )
		);
		IF v_cnt = 0 THEN
			-- make them a member
			begin
				insert into security.group_members (group_sid_id, member_sid_id)
					VALUES (r.ind_sid, r.user_sid);
				dbms_output.put_line(r.label);
			exception
				when dup_val_on_index then 
					null;
			end;
		END IF;
	end loop;
end;
/

   	   	 
	   	 
begin
	for r in (
		select host, ind_root_sid, region_root_sid from customer where host not in ('survey.credit360.com','vancitytest.credit360.com','junkhsbc.credit360.com')
	)
	loop
		user_pkg.logonadmin(r.host);
		acl_pkg.PropogateACEs(security_pkg.getact, r.ind_root_sid);
		acl_pkg.PropogateACEs(security_pkg.getact, r.region_root_sid);
	end loop;
end;
/	 
	   	 
@..\csr_data_body	   	 
	   	 
@update_tail
