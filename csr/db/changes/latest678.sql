-- Please update version.sql too -- this keeps clean builds in sync
define version=678
@update_header

begin
	user_pkg.logonadmin(timeout => 86400);
	for r in (select app_sid from csr.customer where aggregation_engine_version < 4) loop
		security_pkg.setapp(r.app_sid);

		-- clear out any jobs in the queue -- we're about to add in all possible jobs anyway
		DELETE 
		  FROM csr.stored_calc_job 
		 WHERE app_sid = r.app_sid;
	
	    -- kill all values for calculated inds -- normal calc values aren't meant to be in there,
	    -- and stored calc values / aggregates are all going to be recalculated
	    -- also kill all stored calc values for non-calculated inds
	    -- the new rule is that you can only have stored calc values for stored calc inds
	    -- to save data craziness
	    INSERT INTO csr.temp_val_id	(app_sid, val_id)
	    	SELECT v.app_sid, v.val_id 
	    	  FROM csr.val v, csr.ind i 
	    	 WHERE v.app_sid = r.app_sid 
	    	   AND v.app_sid = i.app_sid AND v.ind_sid = i.ind_sid 
	    	   AND (i.ind_type != 0 OR v.source_type_id = 6);
	
		-- Kill all the aggregates, plus any residual stored calc values as well in case of rag1->3
		INSERT INTO temp_val_id (app_sid, val_id)
			SELECT v.app_sid, v.val_id
			  FROM csr.val v
			 WHERE v.app_sid = r.app_sid AND v.source_type_id = 5;
			     	
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
		
		INSERT INTO csr.stored_calc_job (ind_sid, region_sid, start_dtm, end_dtm)
			SELECT i.ind_sid, (SELECT MIN(region_sid) FROM region), 
				  (SELECT NVL(MIN(period_start_dtm),TO_DATE('1990-01-01','yyyy-mm-dd')) FROM val where source_type_id not in (5,6)), 
				  (SELECT NVL(MAX(period_end_dtm),TO_DATE('2020-01-01','yyyy-mm-dd')) FROM val where source_type_id not in (5,6))
			  FROM csr.ind i
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	    UPDATE csr.customer 
	       SET aggregation_engine_version = 4
	     WHERE app_sid = r.app_sid;
    end loop;
END;
/

alter table csr.customer drop constraint ck_aggregation_engine_version;
alter table csr.customer add constraint ck_aggregation_engine_version check (aggregation_engine_version in (4));

@update_tail
