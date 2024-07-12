		 
DECLARE
	v_act VARCHAR(38);
	CURSOR c IS
		SELECT vc.ind_sid, vc.region_sid, vc.period_start_dtm, vc.period_end_dtm, v.val_id 
		  FROM VAL v, VAL_CHANGE vc, IND i 
		 WHERE v.period_end_dtm <='1 Jan 2004'  
		   AND v.ind_sid =i.ind_sid AND i.app_sid = 284569
		   AND v.last_val_change_id = vc.val_change_id AND changed_dtm>SYSDATE-1;	
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN c LOOP
		UPDATE VAL SET locked =0 WHERE val_id = r.val_id; -- unlock
		Indicator_Pkg.RollbackToDate(v_act, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, SYSDATE - 1);
		UPDATE VAL SET locked = 1 WHERE val_id = r.val_id; -- lock
	END LOOP;
END;