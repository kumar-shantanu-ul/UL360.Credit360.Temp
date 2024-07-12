-- Please update version.sql too -- this keeps clean builds in sync
define version=602
@update_header

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../indicator_body
@../calc_body

-- add recalc jobs for rag4 sites to correct an issue where not everything was being calculated
-- (yes, again! -- less likely this time but still worth doing...)
begin
	for r in (select host, app_sid from csr.customer where aggregation_engine_version=4) loop
		dbms_output.put_line('doing '||r.host||' ('||r.app_sid||')');
		update csr.calc_job_lock
		   set dummy = 1
		 where app_sid = r.app_sid;
		delete
		  from csr.stored_calc_job
		 where app_sid = r.app_sid
		   and processing = 0;
		insert into csr.stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
			select v.app_sid, v.ind_sid, v.region_sid, min(v.period_start_dtm), max(v.period_end_dtm)
			  from csr.val v
			 where v.app_sid = r.app_sid
			 group by v.app_sid, v.ind_sid, v.region_sid;
		commit;
	end loop;
end;
/

@update_tail
