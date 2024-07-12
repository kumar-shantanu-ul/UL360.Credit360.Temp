PROMPT Enter a host or ALL
define host=&&1
declare
	v_host varchar2(4000) := '&host';
begin
	if v_host = 'ALL' then
		v_host := null;
	end if;
	security.user_pkg.logonadmin(v_host);
	delete from csr.calc_job_ind where (app_sid, calc_job_id) in (select app_sid, calc_job_id from csr.calc_job where (app_sid, scenario_run_sid) in (select app_sid, scenario_run_sid from csr.scenario_run where (app_sid, scenario_sid) in (select app_sid, scenario_sid from csr.scenario where file_based=1)));
	delete from csr.calc_job_aggregate_ind_group where (app_sid, calc_job_id) in (select app_sid, calc_job_id from csr.calc_job where (app_sid, scenario_run_sid) in (select app_sid, scenario_run_sid from csr.scenario_run where (app_sid, scenario_sid) in (select app_sid, scenario_sid from csr.scenario where file_based=1)));
	delete from csr.calc_job where (app_sid, scenario_run_sid) in (select app_sid, scenario_run_sid from csr.scenario_run where (app_sid, scenario_sid) in (select app_sid, scenario_sid from csr.scenario where file_based=1));
	delete from csr.scenario_auto_run_request where (app_sid, scenario_sid) in 
	  (select app_sid,scenario_sid from csr.scenario where file_based=1);
	insert into csr.scenario_auto_run_request (app_sid,scenario_sid,full_recompute,delay_publish_scenario)
		select app_sid,scenario_sid,1,0 from csr.scenario where file_based=1;
	commit;	
end;
/
exit
