BEGIN
	user_pkg.logonadmin('&&1');
	delete from actions.task_recalc_job where app_sid = SYS_CONTEXT('SECURITY','APP');
	for r in (
		select project_sid from actions.project where app_sid = SYS_CONTEXT('SECURITY','APP')
	)
	loop
		update actions.task
			set weighting = 0
		 where project_sid = r.project_sid;
		securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), r.project_sid);
	end loop;
	delete from actions.task_period_status where app_sid = SYS_CONTEXT('SECURITY','APP');
	commit;
END;
/
quit;
