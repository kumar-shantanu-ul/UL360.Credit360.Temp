-- Please update version.sql too -- this keeps clean builds in sync
define version=610
@update_header

DECLARE
    v_app_sid 						security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonadmin;
	FOR r in (SELECT host,app_sid FROM csr.customer WHERE aggregation_engine_version <= 2) LOOP
		dbms_output.put_line('doing '||r.host);
		security_pkg.setapp(r.app_sid);
		v_app_sid := r.app_sid;

		-- clear out any jobs in the queue -- we're about to add in all possible jobs anyway
		DELETE 
		  FROM csr.stored_calc_job 
		 WHERE app_sid = v_app_sid;
		DELETE
		  FROM csr.region_recalc_job
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
		INSERT INTO temp_val_id (app_sid, val_id)
			SELECT v.app_sid, v.val_id
			  FROM csr.val v
			 WHERE v.app_sid = v_app_sid AND v.source_type_id = 5;
			     	
		UPDATE csr.imp_val
		   SET set_val_id = null
		 WHERE (app_sid, set_val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);
	
		DELETE
		  FROM csr.val_accuracy
		 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);
	
		DELETE
		  FROM csr.val_file
		 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);
	
		DELETE
		  FROM csr.val
		 WHERE (app_sid, val_id) IN (SELECT app_sid, val_id FROM csr.temp_val_id);
		
		update csr.val
		   set csr.source_type_id = 0
		 where csr.source_type_id = 6 
		   and ind_sid in (select ind_sid from csr.ind where ind_type = 0);
		if sql%rowcount != 0 then
			dbms_output.put_line(sql%rowcount||' stored calc values found, converted to normal');
		end if;
		update csr.ind set do_temporal_aggregation=1 where app_sid = v_app_sid;
		
		INSERT INTO csr.stored_calc_job (ind_sid, region_sid, start_dtm, end_dtm)
			SELECT i.ind_sid, (SELECT MIN(region_sid) FROM csr.region), 
				  (SELECT NVL(MIN(period_start_dtm),TO_DATE('1990-01-01','yyyy-mm-dd')) FROM csr.val where source_type_id not in (5,6)), 
				  (SELECT NVL(MAX(period_end_dtm),TO_DATE('2020-01-01','yyyy-mm-dd')) FROM csr.val where source_type_id not in (5,6))
			  FROM ind i
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	    UPDATE csr.customer 
	       SET aggregation_engine_version = 4
	     WHERE app_sid = v_app_sid;
	     
	    COMMIT;
	END LOOP;
END;
/

@update_tail
