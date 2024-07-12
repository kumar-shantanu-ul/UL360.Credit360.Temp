CREATE OR REPLACE PACKAGE BODY ACTIONS.gantt_pkg
IS

PROCEDURE FetchFilteredData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_project_sids			IN	security_pkg.T_SID_IDS,
	in_status_ids			IN	security_pkg.T_SID_IDS,
	in_period_status_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm			IN	DATE						DEFAULT NULL,
	in_end_dtm				IN	DATE						DEFAULT NULL,
	out_task				OUT	security_pkg.T_OUTPUT_CUR,
	out_period				OUT	security_pkg.T_OUTPUT_CUR
)
AS	
	v_region_sid			security_pkg.T_SID_ID;
	v_project_sids			security.T_SID_TABLE;
	v_status_ids			security.T_SID_TABLE;
	v_period_status_ids		security.T_SID_TABLE;
	v_project_count			NUMBER;
	v_status_count			NUMBER;
	v_period_status_count	NUMBER;
BEGIN

	-- parameter < 0 means NULL
	v_region_sid := CASE WHEN in_region_sid < 0 THEN NULL ELSE in_region_sid END;
	
	v_project_sids := security_pkg.SidArrayToTable(in_project_sids);
	SELECT COUNT(*) INTO v_project_count FROM TABLE(v_project_sids);
	
	v_status_ids := security_pkg.SidArrayToTable(in_status_ids);
	SELECT COUNT(*) INTO v_status_count FROM TABLE(v_status_ids);
	
	v_period_status_ids := security_pkg.SidArrayToTable(in_period_status_ids);
	SELECT COUNT(*) INTO v_period_status_count FROM TABLE(v_period_status_ids);
	
	
	IF in_region_sid = -2 THEN
		SELECT region_sid
		  INTO v_region_sid
		  FROM csr.region_owner
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END IF;

	-- Look-up the user's task sids once to imporve speed
	-- Actually we decided that the gantt chart should show everything
	-- We'll leave the mechanisim in place however in case we ever need to use it in future
	DELETE FROM temp_task_sids;
	INSERT INTO temp_task_sids (task_sid) (
		SELECT task_sid
		  --FROM v$user_initiatives
		  FROM task
	);

	IF v_region_sid IS NULL THEN	
	-- Without region filter
		
		OPEN out_task FOR
			SELECT o.lvl,
				t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name, t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
				CASE WHEN in_start_dtm > t.start_dtm THEN in_start_dtm ELSE t.start_dtm END start_dtm,
				CASE WHEN in_end_dtm < t.end_dtm THEN in_end_dtm ELSE t.end_dtm END end_dtm,
				t.fields_xml, t.is_container, t.internal_ref, t.period_duration, 
				t.budget, t.short_name, t.last_task_period_dtm, t.owner_sid, t.created_dtm, t.input_ind_sid, 
				t.target_ind_sid, t.output_ind_sid, t.weighting, t.action_type, t.entry_type, f.region_sid,
				f.geo_type, f.geo_city_id, f.geo_country, f.geo_region, f.geo_longitude, f.geo_latitude,
				ts.is_live, ts.is_rejected, ts.is_stopped, pr.icon project_icon, TRUNC(SYSDATE, 'MONTH') current_month,
				rgn.description region_desc, COUNT(*) OVER (PARTITION BY f.task_sid) region_count
			  FROM task t, task_status ts, project pr, csr.v$region rgn, (
				SELECT DISTINCT t.task_sid, tr.region_sid, r.geo_type, r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude
			      FROM task t, task_region tr, csr.region r
			     WHERE r.region_sid(+) = tr.region_sid
				   AND tr.task_sid(+) = t.task_sid
			     START WITH t.task_sid IN (
			     		SELECT task_sid FROM temp_task_sids
			     	)
			       AND (project_sid = DECODE(v_project_count, 0, project_sid, NULL) OR project_sid IN (
			    		SELECT column_value 
			    		  FROM TABLE(v_project_sids)
			    	))
			       AND (project_sid IN (
			    		SELECT project_sid
			    		  FROM project
			    		 WHERE icon IS NOT NULL -- Hmm, trying to filter out normal actions again - this needs a flag.
			    	))
			   	   AND (task_status_id = DECODE(v_status_count, 0, task_status_id, NULL) OR task_status_id IN (
			   	  		SELECT column_value 
			   	  		  FROM TABLE(v_status_ids)
			   	  	))
		   	   	   AND (t.task_sid = DECODE(v_period_status_count, 0, t.task_sid, NULL) OR t.task_sid IN (
		   	  	   		SELECT tp.task_sid 
		   	  	   		  FROM task t, task_period tp, TABLE(v_period_status_ids) 
		   	  	   		 WHERE t.task_sid = tp.task_sid 
		   	  	   		   AND tp.start_dtm = t.last_task_period_dtm 
		   	  	   		   AND tp.task_period_status_id = column_value
		   	  	   	))
			   	  AND end_dtm > NVL(in_start_dtm, start_dtm)
			   	  AND start_dtm < NVL(in_end_dtm, end_dtm)
			   	  	CONNECT BY PRIOR parent_task_sid = t.task_sid
			) f, (
				SELECT ROWNUM rn, LEVEL lvl, task_sid
				  FROM task
					START WITH parent_task_sid IS NULL
					CONNECT BY PRIOR task_sid = parent_task_sid
						ORDER SIBLINGS BY start_dtm ASC, name ASC
			) o
			WHERE t.task_sid = o.task_sid
			  AND f.task_sid = o.task_sid
			  AND ts.task_status_id = t.task_status_id
			  AND pr.project_sid = t.project_sid
			  AND rgn.region_sid(+) = f.region_sid
				  ORDER BY o.rn;
			
		OPEN out_period FOR
			SELECT x.lvl, x.task_sid, x.project_sid, y.start_dtm, y.task_period_status_id, y.end_dtm, 
				y.approved_dtm, y.approved_by_sid, y.public_comment_approved_dtm, y.public_comment_approved_by_sid, 
				y.entered_dtm, y.entered_by_sid, y.fields_xml, y.region_sid,
				y.status_label, y.status_colour, y.status_special_meaning, y.status_means_pct_complete
			  FROM (
				SELECT DISTINCT 1 lvl, t.task_sid, t.project_sid
				  FROM task t
				 START WITH t.task_sid IN (
		     			SELECT task_sid FROM temp_task_sids
		     	    )
				  AND (project_sid = DECODE(v_project_count, 0, project_sid, NULL) OR project_sid IN (
			    		SELECT column_value 
			    		  FROM TABLE(v_project_sids)
			    	))
			   	  AND (task_status_id = DECODE(v_status_count, 0, task_status_id, NULL) OR task_status_id IN (
			   	  		SELECT column_value 
			   	  		  FROM TABLE(v_status_ids)
			   	  	))
		   	   	  AND (task_sid = DECODE(v_period_status_count, 0, task_sid, NULL) OR task_sid IN (
		   	  	   		SELECT tp.task_sid 
		   	  	   		  FROM task t, task_period tp, TABLE(v_period_status_ids) 
		   	  	   		 WHERE t.task_sid = tp.task_sid 
		   	  	   		   AND tp.start_dtm = t.last_task_period_dtm 
		   	  	   		   AND tp.task_period_status_id = column_value
		   	  	   	))
		   	  	   AND end_dtm > NVL(in_start_dtm, start_dtm)
		   	  	   AND start_dtm < NVL(in_end_dtm, end_dtm)
		   	  	   	CONNECT BY PRIOR parent_task_sid = task_sid
			) x, (
				SELECT t.task_sid, t.start_dtm, t.project_sid, t.task_period_status_id, t.end_dtm, t.approved_dtm, 
					t.approved_by_sid, t.public_comment_approved_dtm, t.public_comment_approved_by_sid, t.entered_dtm, 
					t.entered_by_sid, t.fields_xml, t.region_sid,
					tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
					tps.means_pct_complete status_means_pct_complete
				  FROM task_period t, task_period_status tps, project_task_period_status ptps, project pr
				 WHERE pr.app_sid = SYS_CONTEXT('SECURITY','APP')
				   AND t.project_sid = pr.project_sid
				   AND t.start_dtm >= NVL(in_start_dtm, t.start_dtm)
		   	  	   AND t.end_dtm <= NVL(in_end_dtm, t.end_dtm)
				   AND ptps.project_sid(+) = t.project_sid	
				   AND ptps.task_period_status_id(+) = t.task_period_status_id
				   AND tps.task_period_status_id(+) = ptps.task_period_status_id
				  ORDER BY start_dtm
			) y
			 WHERE y.task_sid = x.task_sid;
			
	ELSE
	-- With region filter
	
		OPEN out_task FOR
			SELECT o.lvl,
				t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name, t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
				CASE WHEN in_start_dtm > t.start_dtm THEN in_start_dtm ELSE t.start_dtm END start_dtm,
				CASE WHEN in_end_dtm < t.end_dtm THEN in_end_dtm ELSE t.end_dtm END end_dtm,
				t.fields_xml, t.is_container, t.internal_ref, t.period_duration, 
				t.budget, t.short_name, t.last_task_period_dtm, t.owner_sid, t.created_dtm, t.input_ind_sid, 
				t.target_ind_sid, t.output_ind_sid, t.weighting, t.action_type, t.entry_type, f.region_sid,
				ts.is_live, ts.is_rejected, ts.is_stopped, pr.icon project_icon, TRUNC(SYSDATE, 'MONTH') current_month,
				rgn.description region_desc, COUNT(*) OVER (PARTITION BY f.task_sid) region_count
			  FROM task t, task_status ts, project pr, csr.v$region rgn, (
				SELECT DISTINCT t.task_sid, tr.region_sid
			      FROM task t, task_region tr
			    WHERE tr.task_sid(+) = t.task_sid
			      START WITH t.task_sid IN (
			     		SELECT task_sid FROM temp_task_sids
			        )
			      AND tr.region_sid IN (
					   	SELECT region_sid sid_id
						  FROM csr.region
						 	START WITH region_sid = v_region_sid
						 	CONNECT BY PRIOR region_sid = parent_sid
			   	    )
			      AND (t.project_sid = DECODE(v_project_count, 0, t.project_sid, NULL) OR t.project_sid IN (
			    		SELECT column_value 
			    		  FROM TABLE(v_project_sids)
			    	))
			   	  AND (t.task_status_id = DECODE(v_status_count, 0, t.task_status_id, NULL) OR t.task_status_id IN (
			   	  		SELECT column_value 
			   	  		  FROM TABLE(v_status_ids)
			   	  	))
		   	   	  AND (t.task_sid = DECODE(v_period_status_count, 0, t.task_sid, NULL) OR t.task_sid IN (
		   	  	   		SELECT tp.task_sid 
		   	  	   		  FROM task t, task_period tp, TABLE(v_period_status_ids) 
		   	  	   		 WHERE t.task_sid = tp.task_sid 
		   	  	   		   AND tp.start_dtm = t.last_task_period_dtm 
		   	  	   		   AND tp.task_period_status_id = column_value
		   	  	   	))
			   	  AND end_dtm > NVL(in_start_dtm, start_dtm)
			   	  AND start_dtm < NVL(in_end_dtm, end_dtm)
			   	  	CONNECT BY PRIOR t.parent_task_sid = t.task_sid
			) f, (
				SELECT ROWNUM rn, LEVEL lvl, task_sid
				  FROM task
					START WITH parent_task_sid IS NULL
					CONNECT BY PRIOR task_sid = parent_task_sid
						ORDER SIBLINGS BY start_dtm ASC, name ASC
			) o
			  WHERE t.task_sid = o.task_sid
			    AND f.task_sid = o.task_sid
			    AND ts.task_status_id = t.task_status_id
			    AND pr.project_sid = t.project_sid
			    AND rgn.region_sid(+) = f.region_sid
			   		ORDER BY o.rn;
			 
		   	  
		OPEN out_period FOR
			SELECT x.lvl, y.task_sid, y.start_dtm, y.project_sid, y.task_period_status_id, y.end_dtm, 
				y.approved_dtm, y.approved_by_sid, y.public_comment_approved_dtm, y.public_comment_approved_by_sid, 
				y.entered_dtm, y.entered_by_sid, y.fields_xml, y.region_sid,
				y.status_label, y.status_colour, y.status_special_meaning, y.status_means_pct_complete
			  FROM (
				SELECT DISTINCT 1 lvl, t.task_sid
			      FROM task t, task_region tr
			    WHERE tr.task_sid(+) = t.task_sid
			      START WITH t.task_sid IN (
		     			SELECT task_sid FROM temp_task_sids
		     		)
			      AND tr.region_sid IN (
					   	SELECT region_sid sid_id
						  FROM csr.region
						 	START WITH region_sid = v_region_sid
						 	CONNECT BY PRIOR region_sid = parent_sid
				   	)
			      AND (t.project_sid = DECODE(v_project_count, 0, t.project_sid, NULL) OR t.project_sid IN (
			    		SELECT column_value 
			    		  FROM TABLE(v_project_sids)
			    	))
			   	  AND (t.task_status_id = DECODE(v_status_count, 0, t.task_status_id, NULL) OR t.task_status_id IN (
			   	  		SELECT column_value 
			   	  		  FROM TABLE(v_status_ids)
			   	  	))
		   	   	  AND (t.task_sid = DECODE(v_period_status_count, 0, t.task_sid, NULL) OR t.task_sid IN (
		   	  	   		SELECT tp.task_sid 
		   	  	   		  FROM task t, task_period tp, TABLE(v_period_status_ids) 
		   	  	   		 WHERE t.task_sid = tp.task_sid 
		   	  	   		   AND tp.start_dtm = t.last_task_period_dtm 
		   	  	   		   AND tp.task_period_status_id = column_value
		   	  	   	))
			   	  AND end_dtm > NVL(in_start_dtm, start_dtm)
			   	  AND start_dtm < NVL(in_end_dtm, end_dtm)
			   	  	CONNECT BY PRIOR t.parent_task_sid = t.task_sid
			) x, (
				SELECT t.task_sid, t.start_dtm, t.project_sid, t.task_period_status_id, t.end_dtm, t.approved_dtm, 
					t.approved_by_sid, t.public_comment_approved_dtm, t.public_comment_approved_by_sid, t.entered_dtm, 
					t.entered_by_sid, t.fields_xml, t.region_sid,
					tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
					tps.means_pct_complete status_means_pct_complete
				  FROM task_period t, task_period_status tps, project_task_period_status ptps, project pr
				 WHERE pr.app_sid = SYS_CONTEXT('SECURITY','APP')
				   AND t.project_sid = pr.project_sid
				   AND t.start_dtm >= NVL(in_start_dtm, t.start_dtm)
		   	  	   AND t.end_dtm <= NVL(in_end_dtm, t.end_dtm)
				   AND ptps.project_sid(+) = t.project_sid	
				   AND ptps.task_period_status_id(+) = t.task_period_status_id
				   AND tps.task_period_status_id(+) = ptps.task_period_status_id
				  ORDER BY start_dtm
			) y	
			 WHERE y.task_sid = x.task_sid;
	END IF;
	
END;

PROCEDURE GetTaskRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid '||in_task_sid);
	END IF;	
	
	OPEN out_cur FOR
		SELECT r.region_sid, r.description
		  FROM csr.v$region r, task_region tr
		 WHERE r.region_sid = tr.region_sid
		   AND tr.task_sid = in_task_sid;
END;

-- Includes values for static metrics summed over the entire project period (single row per metric) and 
-- periodic metrics from the start of the project to the requested month (a row for each month per metric)
PROCEDURE GetMetricsForPeriod(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_month_dtm				IN	task.start_dtm%TYPE,
	out_month					OUT	security_pkg.T_OUTPUT_CUR,
	out_cumv					OUT	security_pkg.T_OUTPUT_CUR,
	out_uom						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_upto_month				task.start_dtm%TYPE;
	v_ind_sid					security_pkg.T_SID_ID;
BEGIN

	v_upto_month := TRUNC(in_month_dtm, 'MONTH');

	-- fetch the project and output ind from the task
	SELECT project_sid, output_ind_sid
	  INTO v_project_sid, v_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	OPEN out_month FOR 
		SELECT t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
			t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id,
			ROUND(NVL(v.entry_val_number, v.val_number), t.input_dp) val, 0 forecast
		  FROM (
	        SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid, pit.pos, i.measure_sid, t.start_dtm, t.end_dtm, pit.saving_template_id, pit.input_dp
	          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst, csr.ind i
	         WHERE it.ind_template_id = pit.ind_template_id
	           AND pit.project_sid = v_project_sid
	           AND pit.update_per_period = 1
	           AND inst.task_sid = in_task_sid
			   AND inst.from_ind_template_id = it.ind_template_id
			   AND t.task_sid = inst.task_sid
			   AND i.ind_sid(+) = inst.ind_sid
		    ) t, csr.val v
		 WHERE v.ind_sid(+) = t.ind_sid
		   AND v.region_sid(+) = in_region_sid
		   AND v.period_start_dtm(+) = v_upto_month
		UNION
		SELECT t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
			t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id,
			ROUND(NVL(v.entry_val_number, v.val_number), t.input_dp) val, 1 forecast
		  FROM (
	        SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid, pit.pos, i.measure_sid, t.start_dtm, t.end_dtm, NULL saving_template_id, pit.input_dp
	          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst, csr.ind i
	         WHERE it.ind_template_id = pit.saving_template_id
	           AND pit.project_sid = v_project_sid
	           AND pit.update_per_period = 1
	           AND inst.task_sid = in_task_sid
			   AND inst.from_ind_template_id = it.ind_template_id
			   AND t.task_sid = inst.task_sid
			   AND i.ind_sid(+) = inst.ind_sid
		    ) t, csr.val v
		 WHERE v.ind_sid(+) = t.ind_sid
		   AND v.region_sid(+) = in_region_sid
		   AND v.period_start_dtm(+) = v_upto_month		
		;
	
	OPEN out_cumv FOR 
		SELECT ind_template_id, name, description, input_label, ind_sid, 
			pos, measure_sid, entry_measure_conversion_id, 
			-- Hmm, this gets retuned as a string sometimes if not cast, bizarre!
			CAST(DECODE(saving_template_id, -1, NULL, saving_template_id) AS NUMBER(10)) saving_template_id, 
			ROUND(val, input_dp) val
			FROM (
				SELECT t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
					t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id, t.input_dp,
					NVL(SUM(v.entry_val_number), SUM(v.val_number)) val
				  FROM (
			        SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid, pit.pos, i.measure_sid, t.start_dtm, t.end_dtm, pit.saving_template_id, pit.input_dp
			          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst, csr.ind i
			         WHERE it.ind_template_id = pit.ind_template_id
			           AND pit.project_sid = v_project_sid
			           AND pit.update_per_period = 1
			           AND inst.task_sid = in_task_sid
					   AND inst.from_ind_template_id = it.ind_template_id
					   AND t.task_sid = inst.task_sid
					   AND i.ind_sid(+) = inst.ind_sid
				    ) t, csr.val v
				 WHERE v.ind_sid(+) = t.ind_sid
				   AND v.region_sid(+) = in_region_sid
				   AND v.period_start_dtm(+) >= t.start_dtm
		           AND v.period_start_dtm(+) <= v_upto_month
				   	GROUP BY t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
				   		t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id, t.input_dp
				UNION
				SELECT t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
					t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id, t.input_dp,
					NVL(SUM(v.entry_val_number), SUM(v.val_number)) val
				  FROM (
			        SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid, pit.pos, i.measure_sid, t.start_dtm, t.end_dtm, -1 saving_template_id, pit.input_dp
			          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst, csr.ind i
			         WHERE it.ind_template_id = pit.saving_template_id
			           AND pit.project_sid = v_project_sid
			           AND pit.update_per_period = 1
			           AND inst.task_sid = in_task_sid
					   AND inst.from_ind_template_id = it.ind_template_id
					   AND t.task_sid = inst.task_sid
					   AND i.ind_sid(+) = inst.ind_sid
				    ) t, csr.val v
				 WHERE v.ind_sid(+) = t.ind_sid
				   AND v.region_sid(+) = in_region_sid
				   AND v.period_start_dtm(+) >= t.start_dtm
		           AND v.period_start_dtm(+) <= v_upto_month
				   	GROUP BY t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, 
				   		t.pos, t.measure_sid, v.entry_measure_conversion_id, t.saving_template_id, t.input_dp
			);
		
	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM task_ind_template_instance inst, csr.ind i, csr.measure m, csr.measure_conversion mc
		 WHERE inst.task_sid = in_task_sid
		   AND i.ind_sid = inst.ind_sid
		   AND m.measure_sid = i.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;
END;

END gantt_pkg;
/
