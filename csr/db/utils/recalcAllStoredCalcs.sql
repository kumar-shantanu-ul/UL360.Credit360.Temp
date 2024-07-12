PROMPT please enter: host name to add recalc jobs for
DECLARE
	v_sid	security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin('&&1');
	v_sid := security.security_pkg.getApp;

	delete from csr.val_change_log where app_sid = v_sid;
	FOR r IN (
		SELECT ind_sid 
		  FROM csr.ind 
		 WHERE app_sid = v_sid 
		   AND ind_type = csr.csr_data_pkg.IND_TYPE_STORED_CALC
		   AND active = 1
	)
    LOOP
        update csr.imp_val set set_val_id = null where set_val_id in (
			select val_id from csr.val where ind_sid = r.ind_sid);
		--val_id doesn't exists and there is no foreign key constraint
		/*
		update csr.val_change set val_id = null where val_id in (
			select val_id from csr.val where ind_sid = r.ind_sid);
		*/
        delete from csr.val where ind_sid = r.ind_sid;
       	csr.calc_pkg.AddJobsForCalc(r.ind_sid);
    END LOOP;
	commit;
END;
/
exit