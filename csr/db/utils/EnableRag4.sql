DECLARE
    v_app_sid 						security.security_pkg.T_SID_ID;
BEGIN
    security.user_pkg.logonadmin('&&1', 86400);
    v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- clear out any jobs in the queue -- we're about to add in all possible jobs anyway
	DELETE FROM csr.val_change_log
	 WHERE app_sid = v_app_sid;

    -- kill all values for calculated inds -- normal calc values aren't meant to be in there,
    -- and stored calc values / aggregates are all going to be recalculated
    -- also kill all stored calc values for non-calculated inds
    -- the new rule is that you can only have stored calc values for stored calc inds
    -- to save data craziness
    INSERT INTO csr.temp_val_id	(app_sid, val_id)
    	SELECT v.app_sid, v.val_id 
    	  FROM csr.val v, csr.ind i 
    	 WHERE v.app_sid = v_app_sid 
    	   AND v.app_sid = i.app_sid AND v.ind_sid = i.ind_sid 
    	   AND (i.ind_type != 0 OR v.source_type_id = 6);

	-- Kill all the aggregates, plus any residual stored calc values as well in case of rag1->3
	INSERT INTO csr.temp_val_id (app_sid, val_id)
		SELECT v.app_sid, v.val_id
		  FROM csr.val v
		 WHERE v.app_sid = v_app_sid AND v.source_type_id = 5;
		     	
	UPDATE csr.imp_val
	   SET set_val_id = null
	 WHERE (app_sid, set_val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);

	DELETE FROM csr.val_file
	 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);

	DELETE FROM csr.val
	 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);
	
	INSERT INTO csr.val_change_log (ind_sid, start_dtm, end_dtm)
		SELECT DISTINCT i.ind_sid, c.calc_start_dtm, c.calc_end_dtm
		  FROM csr.ind i, csr.customer c
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = c.app_sid;

    UPDATE csr.customer 
       SET aggregation_engine_version = 4
     WHERE app_sid = v_app_sid;
     
    COMMIT;
END;
/

exit
