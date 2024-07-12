-- Please update version.sql too -- this keeps clean builds in sync
define version=588
@update_header

begin
	-- clean up values for normal calcs introduced by a bug in rag4
	update imp_val
	   set set_val_id = null
	 where (app_sid, imp_val_id) in (select v.app_sid, iv.imp_val_id
	 								   from val v, ind i, imp_val iv
	 								  where v.app_sid = i.app_sid and v.ind_sid = i.ind_sid
	 								    and i.ind_type = 1
	 								    and iv.app_sid = v.app_sid and iv.set_val_id = v.val_id);
	delete
	  from val
	 where (app_sid, val_id) in (select v.app_sid, v.val_id
	  							   from ind i, customer c, val v
	  							  where i.ind_type = 1
	  								and i.app_sid = c.app_sid
	  								and c.aggregation_engine_version = 4
	  								and v.app_sid = i.app_sid
	  								and v.ind_sid = i.ind_sid);
	   
	-- add recalc jobs for rag4 sites to correct an issue where not everything was being calculated
	delete
	  from stored_calc_job
	 where app_sid in (select app_sid from customer where aggregation_engine_version=4)
	   and processing = 0;
	insert into stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
		select v.app_sid, v.ind_sid, v.region_sid, min(v.period_start_dtm), max(v.period_end_dtm)
		  from val v, customer c
		 where v.app_sid = c.app_sid and c.aggregation_engine_version = 4
		 group by v.app_sid, v.ind_sid, v.region_sid;
end;
/

@update_tail
