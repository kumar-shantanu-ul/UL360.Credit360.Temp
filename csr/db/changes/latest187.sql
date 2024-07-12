-- Please update version.sql too -- this keeps clean builds in sync
define version=187
@update_header

begin
    for r in (
        select c.app_sid, count(*), count(distinct i.ind_sid)
          from ind i, customer c, security.securable_object so, val v, calc_dependency cd
         where so.parent_sid_id = c.app_sid
           and so.name='Regions'
           and so.sid_id = v.region_sid
           and i.app_sid = c.app_sid
           and i.ind_type = 3
           and v.ind_sid = i.ind_sid
           and cd.ind_sid = i.ind_sid
        group by c.app_sid
        order by count(*) desc) loop

		delete from region_list;

		insert into region_list (region_sid)
            select v.val_id
              from ind i, customer c, val v
             where i.app_sid = c.app_sid
               and c.app_sid=r.app_sid
               and i.ind_type = 3
               and i.ind_sid = v.ind_sid and c.region_root_sid <> v.region_sid;
        
        update imp_val set set_val_id = null where set_val_id in (select region_sid from region_list);
        update val set last_val_change_id = null where val_id in (select region_sid from region_list);
        delete from val_change where val_id in (select region_sid from region_list);
        delete from val where val_id in (select region_sid from region_list);
        
        delete from region_list;
        insert into region_list (region_sid)
            select v.val_id
              from ind i, customer c, val v
             where i.app_sid = c.app_sid
               and c.app_sid=r.app_sid
               and i.ind_type = 3
               and i.ind_sid = v.ind_sid and c.region_root_sid = v.region_sid;
	                           
        insert into val (val_id, ind_sid, region_Sid,  period_start_dtm, period_end_dtm, val_number,
        		   status, alert, flags, source_id, entry_measure_conversion_id, entry_val_number,
        		   note, source_type_id, aggr_est_number)
        	select val_id_seq.nextval, v.ind_sid, tl.region_sid, period_start_dtm, period_end_dtm, val_number,
        		   status, alert, flags, source_id, entry_measure_conversion_id, entry_val_number,
        		    note, source_type_id, aggr_est_number
              from val v, (
	                select rx.region_sid
	                  from region rx, region_tree rt, customer c
	                 where rt.app_sid = c.app_sid 
	                   and c.app_sid = rx.app_sid
	                   and is_primary = 1
	                   and rt.region_tree_root_sid = rx.parent_sid ) tl, region_list vi
			  where vi.region_sid = v.val_id;

        update imp_val set set_val_id = null where set_val_id in (select region_sid from region_list);
        update val set last_val_change_id = null where val_id in (select region_sid from region_list);
        delete from val_change where val_id in (select region_sid from region_list);
        delete from val where val_id in (select region_sid from region_list);

		INSERT INTO region_recalc_job (app_sid, ind_sid, processing)
			SELECT app_Sid, ind_sid, 0 FROM ind WHERE ind_type = 3 AND app_Sid = r.app_sid
	 	 	MINUS
			SELECT app_sid, ind_sid, 0 FROM region_recalc_job WHERE processing = 0; 
			
		UPDATE ind SET aggregate='DOWN', ind_type = 0 WHERE ind_type = 3  AND app_Sid = r.app_sid;
		
    end loop;
    
    -- fix other inds that don't have values / dependencies too
    UPDATE ind SET aggregate='DOWN', ind_type = 0 WHERE ind_type = 3;
end;
/

@update_tail
