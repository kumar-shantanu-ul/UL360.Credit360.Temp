-- Please update version.sql too -- this keeps clean builds in sync
define version=600
@update_header

@../stored_calc_datasource_body

begin
	-- add recalc jobs for rag4 sites to correct an issue where not everything was being calculated
	update csr.calc_job_lock
	   set dummy = 1
	 where app_sid in (select app_sid from csr.customer where aggregation_engine_version=4);
	delete
	  from csr.stored_calc_job
	 where app_sid in (select app_sid from csr.customer where aggregation_engine_version=4)
	   and processing = 0;
	insert into csr.stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
		select v.app_sid, v.ind_sid, v.region_sid, min(v.period_start_dtm), max(v.period_end_dtm)
		  from csr.val v, csr.customer c
		 where v.app_sid = c.app_sid and c.aggregation_engine_version = 4
		 group by v.app_sid, v.ind_sid, v.region_sid;
end;
/

@update_tail
