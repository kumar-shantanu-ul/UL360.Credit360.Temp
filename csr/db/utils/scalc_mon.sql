column host format a30
column progress format a35
column v format 0
 select app_sid, host, progress
   from (
	 select c.app_sid, substr(c.host,1,30) host, sr.description||' - '||cj.phase_description|| 
	 			decode(total_work, 0, '', ' '||cj.work_done||'/'||cj.total_work||' - '||round(work_done *100 / total_work)||'%') progress,
			cj.updated_dtm, cj.processing
	   from csr.customer c, csr.v$calc_job cj, csr.scenario_run sr
	  where cj.app_sid = c.app_sid and cj.app_sid = sr.app_sid(+) and cj.scenario_run_sid = sr.scenario_run_sid(+)
	  union all 
	 select c.app_sid, substr(c.host,1,30) host, 'Pending job creation '||sum(cnt) description, sysdate updated_dtm, 0 processing
	   from (select app_sid, count(*) cnt from csr.val_change_log group by app_sid
	   		  union all
	   		 select app_sid, count(*) cnt from csr.aggregate_ind_calc_job group by app_sid
	   		  union all
	   		 select app_sid, count(*) cnt from csr.sheet_val_change_log group by app_sid
	   		  union all
	   		 select app_sid, count(*) cnt from csr.scenario_man_run_request group by app_sid 
	   		  union all
			 select app_sid, count(*) cnt from csr.scenario_auto_run_request group by app_sid) j, csr.customer c
	  where c.app_sid = j.app_sid
	  group by c.app_sid, c.host
  )
  order by processing desc, updated_dtm desc
;  
 