PROMPT Enter host
declare
	v_calc_start_dtm				csr.customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					csr.customer.calc_end_dtm%TYPE;
begin
	security.user_pkg.logonadmin('&&1');
	delete from csr.val_change_log
	 where app_sid = sys_context('security','app');

	select calc_start_dtm, calc_end_dtm
	  into v_calc_start_dtm, v_calc_end_dtm
	  from csr.customer;

	insert into csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
		select i.app_sid, i.ind_sid, v_calc_start_dtm, v_calc_end_dtm
		  from csr.ind i
		 where i.app_sid = sys_context('security','app')
		 group by i.app_sid, i.ind_sid;

	insert into csr.aggregate_ind_calc_job (app_sid, aggregate_ind_group_id, start_dtm, end_dtm)
		select aig.app_sid, aig.aggregate_ind_group_id, v_calc_start_dtm, v_calc_end_dtm
		  from csr.aggregate_ind_group aig
		 where aig.app_sid = sys_context('security','app');
end;
/
exit
