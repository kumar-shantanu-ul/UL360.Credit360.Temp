

-- converts all annuals to monthly breakdown, applying a "realistic" curve
DECLARE
	TYPE T_MONTHS IS VARRAY(12) OF NUMBER;
	v_mult T_MONTHS := T_MONTHS(5.5,6,7,7.4,8.4,9,9.2,9.5,10.2,9.6,9.2,9);
	CURSOR c IS
		SELECT val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number FROM VAL FOR UPDATE;
	r c%ROWTYPE;
	v_m NUMBER(10);
	v_d DATE;
BEGIN
	FOR r IN c LOOP
		IF r.PERIOD_END_DTM-r.PERIOD_START_DTM>360 AND r.PERIOD_END_DTM-r.PERIOD_START_DTM<370 THEN 
			UPDATE VAL SET STATUS = 1 WHERE CURRENT OF c;
			v_d:=r.PERIOD_START_DTM;
			FOR v_m IN 1..12 LOOP
				INSERT INTO VAL (VAL_ID, ind_sid, region_sid, period_Start_dtm, period_end_dtm, val_number, status)	
					VALUES (val_id_seq.NEXTVAL, r.ind_sid, r.region_sid, v_d, ADD_MONTHS(v_d,1), ROUND((r.val_number*v_mult(v_m))/100,2),0);
				v_d:=ADD_MONTHS(v_d,1);
			END LOOP;
		END IF;
	END LOOP;
	DELETE FROM VAL WHERE status = 1;
END;
