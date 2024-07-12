

DECLARE
	v_act 			security_pkg.T_ACT_ID;
	v_app_sid		security_pkg.T_SID_ID := --1223176;
    v_val_id		NUMBER(10);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//csr/users/richard',500,v_act);
	FOR r IN (
	    SELECT val_pkg.formatperiod(v.period_start_dtm, v.period_end_dtm, NULL) period, i.description indicator_name, r.description region_name, 
	      	v.entry_val_number entered_value, mc.description from_unit, m.description to_unit, 
		NVL(mc.conversion_factor, mcp.conversion_factor) conversion_factor, v.val_number old_value,
	          ROUND(v.entry_val_number *NVL(mc.conversion_factor, mcp.conversion_factor),10) new_value,
		v.ind_sid, v.region_sid, v.period_Start_dtm, v.period_end_dtm, v.source_type_id, v.source_id, v.entry_measure_conversion_id, v.entry_val_number, v.note           
	  FROM MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP, VAL v, IND i, REGION r, MEASURE M
	 WHERE MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)  
	   AND (v.period_start_dtm >= mcp.start_dtm OR mcp.start_dtm IS NULL)
	   AND (v.period_start_dtm < mcp.end_dtm OR mcp.end_dtm IS NULL)
	         AND v.entry_measure_conversion_id = mc.measure_conversion_id
	         AND v.IND_SID = i.IND_SID
	         AND v.REGION_SID = r.REGION_SID
	         AND i.app_sid = v_app_sid
	         AND mc.measure_sid = m.measure_sid
	         AND ROUND(v.entry_val_number *NVL(mc.conversion_factor, mcp.conversion_factor),10) != v.val_number
	       ORDER BY i.description, r.description
	)
	LOOP
		indicator_pkg.SetValueWithReason(v_act,
				r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm,
				r.new_value, 0, r.source_type_id, r.source_id, r.entry_measure_conversion_id, r.entry_val_number, 0,
				'Changed due to modified conversion factor', r.note, v_val_id);
	END LOOP;              
END;