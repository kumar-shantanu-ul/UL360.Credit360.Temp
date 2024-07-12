DECLARE
	v_val_id	NUMBER(10);
	v_cnt		NUMBER(10) := 0;
	v_act				security_pkg.T_ACT_ID;
BEGIN	
	user_pkg.logonadmin('mcdonalds-global.credit360.com');
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	FOR r IN (
		SELECT v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, v.val_number/100 val_number,
			v.flags, v.source_type_id, v.source_id, v.note
		  FROM val v
			JOIN ind i ON v.ind_sid = i.ind_sid
			LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE INSTR(NVL(i.format_mask, m.format_mask),'%') > 0
		   AND source_type_id != 5
		   AND val_number >= 1
	)
	LOOP
		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid => security_pkg.getSid,
			in_ind_sid => r.ind_sid,
			in_region_sid => r.region_sid,
			in_period_start => r.period_start_dtm,
			in_period_end => r.period_end_dtm,
			in_val_number => r.val_number,
			in_flags =>  r.flags,
			in_source_type_id => r.source_type_id,
			in_source_id => r.source_id, 
			in_reason => 'Change to format mask - FB6763',
			in_note => r.note,
			out_val_id => v_val_id
		);
		v_cnt := v_cnt + 1;
	END LOOP;
	DBMS_OUTPUT.PUT_LINE(v_cnt||' rows changed');
END;
/
