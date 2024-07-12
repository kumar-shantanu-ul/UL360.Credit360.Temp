-- XXX: this is broken, calls to indicator_pkg.SetValue no longer match the signature
DECLARE
	CURSOR c IS
		SELECT * FROM VAL WHERE ind_sid IN 
		(SELECT ind_sid FROM IND WHERE parent_sid = 392263)
		ORDER BY IND_SID, REGION_SID, PERIOD_START_DTM;
	r_last 		c%ROWTYPE;
	v_act_id	security_pkg.T_ACT_ID;
	v_val_id	NUMBER(10);
	v_started	BOOLEAN;
	v_new		BOOLEAN;
	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act_id);
	-- go through each row
	v_started := FALSE;
	v_new := TRUE;
	FOR r IN c LOOP
		IF v_started THEN
			-- check to see if we've moved off to some new data, but not filled all the way to end of 2004
			IF r_last.ind_sid != r.ind_sid OR r_last.region_sid != r.region_sid THEN
				-- use last values to feed future years
				v_period_start_dtm := ADD_MONTHS(r_last.period_start_dtm, 12); 
				WHILE v_period_start_dtm < '1 Jan 2005' LOOP
					v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, 12);
					Indicator_Pkg.setValue(v_act_id, r_last.ind_sid, r_last.region_sid, v_period_start_dtm, 
						v_period_end_dtm, r_last.val_number, r_last.verified, r_last.source_id,
						r_last.entry_measure_conversion_id, r_last.entry_val_number, v_val_id);
					v_period_start_dtm := v_period_end_dtm;
				END LOOP;
				v_new := TRUE; -- prod it to check for stuff at start of our new period
			-- hmm, check to see if the periods are contiguious - fill in if not
			ELSIF r.period_start_dtm > r_last.period_end_dtm THEN
				-- use last values to feed future years
				v_period_start_dtm := ADD_MONTHS(r_last.period_start_dtm, 12); 
				WHILE v_period_start_dtm < r.period_start_dtm LOOP
					v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, 12);
					Indicator_Pkg.setValue(v_act_id, r_last.ind_sid, r_last.region_sid, v_period_start_dtm, 
						v_period_end_dtm, r_last.val_number, r_last.verified, r_last.source_id,
						r_last.entry_measure_conversion_id, r_last.entry_val_number, v_val_id);
					v_period_start_dtm := v_period_end_dtm;
				END LOOP;				
			END IF;
		ELSE	
			-- eat first row before getting cracking
			v_started := TRUE;
		END IF;
		-- if this is new, then check period_start_dtm, and back fill to start year (1999?) 
		IF v_new THEN
			v_period_start_dtm := ADD_MONTHS(r.period_start_dtm, -12); 
			WHILE v_period_start_dtm > '1 Jan 1995' LOOP
				v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, 12);
				Indicator_Pkg.setValue(v_act_id, r.ind_sid, r.region_sid, v_period_start_dtm, 
					v_period_end_dtm, r.val_number, r.verified, r.source_id,
					r.entry_measure_conversion_id, r.entry_val_number, v_val_id);
				v_period_start_dtm := ADD_MONTHS(v_period_start_dtm, -12);
			END LOOP;
		END IF;
		v_new := FALSE;
		r_last := r;
	END LOOP;
END;