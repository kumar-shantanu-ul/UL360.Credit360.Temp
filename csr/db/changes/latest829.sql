-- Please update version.sql too -- this keeps clean builds in sync
define version=829
@update_header

-- removed as it calls csr_data_pkg (naughtily) but it's just a fix-script so ok not to run of DT as they don't use this. 

-- BEGIN
-- 	FOR r IN (
-- 		 select c.host, ig.ind_sid, ig.description, ig.aggregate
-- 		   from csr.ind iv
-- 		  join csr.ind ig on ig.map_to_ind_sid = iv.ind_sid
-- 		  join csr.customer c on iv.app_sid = c.app_sid
-- 		  where iv.ind_type = 0
-- 		   and ig.aggregate != 'FORCE SUM'
-- 	)
-- 	LOOP
-- 		DBMS_OUTPUT.PUT_LINE(r.host||': Fixing up ind sid '||r.ind_sid||' - '||r.description||' (was set to '||r.aggregate||')');
-- 		security.user_pkg.logonadmin(r.host);
-- 		
-- 		update csr.ind 
-- 		   set aggregate = 'FORCE SUM'
-- 		 where ind_sid = r.ind_sid;
-- 
-- 		csr.csr_data_pkg.LockApp(1); --csr_data_pkg.LOCK_TYPE_CALC
-- 
-- 		MERGE /*+ALL_ROWS*/ INTO csr.stored_calc_job scj
-- 		USING (SELECT app_sid, ind_sid, MIN(period_start_dtm) period_start_dtm, MAX(period_end_dtm) period_end_dtm
-- 				 FROM csr.val
-- 				WHERE ind_sid = r.ind_sid
-- 				GROUP BY app_sid, ind_sid) v
-- 		   ON (v.app_sid = scj.app_sid AND v.ind_sid = scj.ind_sid AND scj.processing = 0)
-- 		 WHEN MATCHED THEN
-- 			UPDATE 
-- 			   SET scj.start_dtm = LEAST(scj.start_dtm, v.period_start_dtm),
-- 				   scj.end_dtm = GREATEST(scj.end_dtm, v.period_end_dtm)
-- 		 WHEN NOT MATCHED THEN
-- 			INSERT (scj.ind_sid, scj.start_dtm, scj.end_dtm)
-- 			VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);
-- 
-- 	END LOOP;
-- 	
-- 	security.user_pkg.logonadmin;
-- END;
-- /

@..\indicator_body

@update_tail
