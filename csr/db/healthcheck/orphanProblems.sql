drop table duff_data purge;


begin    
    user_pkg.LogonAdmin('barclays.credit360.com');
end;
/

-- this first query pulls values where there is a child region present, but no value, and the 'parent' value is aggregated
create table duff_data as
select val_id, host
  from (
	select v.val_id, v.host, max(case when vc.region_sid is not null then 1 else 0 end) has_child
	  from (
		select v.val_id, c.host, NVL(rp.link_to_region_sid, rp.region_sid) parent_region_sid, v.ind_sid, NVL(rc.link_to_region_sid, rc.region_sid) region_sid, v.period_start_dtm, v.period_end_dtm
		  from val v, ind i, region rp, region rc, customer c
		 where v.region_sid = rp.region_sid
		   and NVL(rp.link_to_region_sid, rp.region_sid) = rc.parent_sid
  		   and rp.app_sid = c.app_sid
		   and v.source_type_id = 5
 		   and v.ind_sid = i.ind_sid
 		   and i.ind_type != 1 -- not a calc
		   and i.aggregate IN ('AVERAGE','FORCE SUM', 'SUM')
 		  -- and v.val_number !=0 
  		   and v.val_number is not null
		   and rp.active = 1
  		   and i.active = 1
  		   and v.app_sid = c.app_sid
  		   and i.app_sid = c.app_sid
  		   and rp.app_sid = c.app_sid
  		   and rc.app_sid = c.app_sid
  		   and c.host = 'barclays.credit360.com'
	)v, val vc
	 where vc.region_sid(+) = v.region_sid
	   and vc.ind_sid(+) = v.ind_sid
	   and vc.period_start_dtm(+) < v.period_end_dtm
	   and vc.period_end_dtm(+) > v.period_start_dtm 
	 group by v.val_id, v.host
  )  
where has_child = 0;

-- and these are all the leaf regions where there's an orphan value
insert into duff_data (val_id, host)
    select v.val_id, 'barclays.credit360.com'
      from val v, ind i
     where region_sid in (
        SELECT NVL(link_to_region_sid, region_sid) region_sid
          FROM region 
         WHERE NVL(link_to_region_sid, region_sid) = region_sid -- ensure we don't recalc anything
           AND CONNECT_BY_ISLEAF = 1
         START WITH parent_sid IN (
            select region_tree_root_sid from region_tree rt, customer c where rt.app_sid = c.app_sid and host='barclays.credit360.com'	
        )
        CONNECT BY PRIOR region_sid = parent_sid
    )
        and v.source_type_id = 5
        and v.ind_sid = i.ind_sid
        and i.ind_type != 1 -- not a calc
        and i.aggregate IN ('AVERAGE','FORCE SUM', 'SUM')
        and v.val_number is not null;


begin
update val_change set val_id = null where val_id in (select val_id from duff_data);
update imp_val set set_val_id = null where set_val_id in (select val_id from duff_data);
delete from val where val_id in (select val_id from duff_Data);
commit;
end;
/

select dd.val_id, host, indicator_pkg.INTERNAL_GetIndPathString(v.ind_sid) ind_path,
	region_pkg.INTERNAL_GetRegionPathString(v.region_sid) region_path, period_start_dtm, period_end_dtm 
  from duff_data dd, val v, region r  
 where dd.val_id = v.val_id 
   and v.region_sid = r.region_sid
 order by host, region_path
