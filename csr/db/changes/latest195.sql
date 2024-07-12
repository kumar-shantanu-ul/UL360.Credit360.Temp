
-- Please update version.sql too -- this keeps clean builds in sync
define version=195
@update_header

BEGIN
	insert into region_recalc_job (app_sid, ind_sid, processing) 
	    select distinct i.app_sid, i.ind_sid, 0 
	      from val v, ind i
	     where trunc(period_start_dtm) <> period_start_dtm and i.ind_sid = v.ind_sid;

	FOR r IN (
		select distinct i.app_sid, i.ind_sid, 0 
		  from val v, ind i
		 where (trunc(period_end_dtm) <> period_end_dtm or trunc(period_start_dtm) <> period_start_dtm) and 
		 	   i.ind_sid = v.ind_sid and ind_type = csr_data_pkg.ind_type_stored_calc
	)
    LOOP
        update val_change set val_id = null where val_id in (
		   select val_id from val where ind_sid = r.ind_sid);
        delete from val where ind_sid = r.ind_sid;
        calc_pkg.AddJobsForCalc(r.ind_sid);
    END LOOP;
 
	update val set period_start_dtm = trunc(period_start_dtm+1/24), period_end_dtm = trunc(period_end_dtm+1/24)
	where period_start_dtm <> trunc(period_start_dtm) or period_end_dtm <> trunc(period_end_dtm);


	update val_change set period_start_dtm = trunc(period_start_dtm+1/24), period_end_dtm = trunc(period_end_dtm+1/24)
	where period_start_dtm <> trunc(period_start_dtm) or trunc(period_end_dtm) <> period_end_dtm;
END;
/


@update_tail

