-- Please update version.sql too -- this keeps clean builds in sync
define version=692
@update_header

@../stored_calc_datasource_body

-- add recalc jobs to correct an issue with propagate down
begin
	for r in (select host, app_sid from csr.customer) loop
		dbms_output.put_line('doing '||r.host||' ('||r.app_sid||')');
		update csr.calc_job_lock
		   set dummy = 1
		 where app_sid = r.app_sid;
		delete
		  from csr.stored_calc_job
		 where app_sid = r.app_sid
		   and processing = 0;
		insert into stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
			select v.app_sid, v.ind_sid, v.region_sid, min(v.period_start_dtm), max(v.period_end_dtm)
			  from csr.val v
			 where v.app_sid = r.app_sid
			 group by v.app_sid, v.ind_sid, v.region_sid;
		commit;
	end loop;
end;
/

@update_tail
