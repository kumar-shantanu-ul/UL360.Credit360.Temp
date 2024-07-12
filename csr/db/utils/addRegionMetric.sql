PROMPT Enter host, the name of the new metric and the measure (new or existing one)

DECLARE
	v_act				 security.security_pkg.T_ACT_ID;
	v_app				 security.security_pkg.T_SID_ID;
	
    v_metrics_folder_sid security.security_pkg.T_SID_ID;
    v_ind_root_sid       security.security_pkg.T_SID_ID;
	v_space_type_id      security.security_pkg.T_SID_ID;
	v_region_type        security.security_pkg.T_SID_ID;
	out_ind_sid			 security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&host');
	
	v_act := security.security_pkg.getACT;
	v_app := security.security_pkg.getApp;
	
	SELECT ind_root_sid 
	  INTO v_ind_root_sid
	  FROM csr.customer
	  WHERE app_sid = v_app;
	
	SELECT MIN(ind_sid)
	  INTO v_metrics_folder_sid
	  FROM csr.v$ind
	 WHERE UPPER(description) = 'METRICS'
	   AND parent_sid = v_ind_root_sid
	   AND app_sid = v_app;
	   
	IF v_metrics_folder_sid IS NULL THEN
		csr.indicator_pkg.CreateIndicator(
			in_parent_sid_id	=> v_ind_root_sid,
			in_name 			=> 'METRICS',
			in_description 		=> 'Metrics',
			out_sid_id			=> v_metrics_folder_sid
		);
	END IF;
	
	-- create the new metric
	csr.region_metric_pkg.MakeMetric(v_metrics_folder_sid, TRIM('&&input_metric_name'), '&&input_measure_name', out_ind_sid);

	-- get the 'Space' region type
	SELECT MIN(region_type)
	  INTO v_region_type
	  FROM csr.region_type
	 WHERE UPPER(label) = UPPER('Space');
	   
	-- get the space type where the metrics will be used
	SELECT MIN(space_type_id)
	  INTO v_space_type_id
	  FROM csr.space_type
	 WHERE UPPER(label) = UPPER('&&space_type')
	   AND app_sid = v_app;
	
	INSERT INTO CSR.REGION_TYPE_METRIC (app_sid, region_type, ind_sid) VALUES (v_app, v_region_type, out_ind_sid);

	INSERT INTO CSR.SPACE_TYPE_REGION_METRIC (app_sid, space_type_id, ind_sid, region_type) VALUES (v_app, v_space_type_id, out_ind_sid, v_region_type);
END;
/
