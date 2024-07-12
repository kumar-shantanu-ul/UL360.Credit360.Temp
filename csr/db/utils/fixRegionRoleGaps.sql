
insert into region_role_member (role_sid, user_sid, inherited_from_sid, region_sid)
with r as (
	 select /*+ALL ROWS*/connect_by_root region_sid root_region_sid, region_sid
	   from region
	  start with region_sid in (
		select distinct inherited_from_sid from region_role_member  
	  )
	connect by prior region_sid = parent_sid
)
	select /*+ALL ROWS*/rrm.role_sid, rrm.user_sid, rrm.inherited_from_sid, r.region_sid
	  from region_role_member rrm
		join r on rrm.inherited_from_sid = r.root_region_sid
   minus
	select /*+ALL ROWS*/role_sid, user_sid, inherited_from_sid, region_sid
	  from region_role_member
 ;


COMMIT;
