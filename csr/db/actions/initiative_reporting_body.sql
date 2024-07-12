CREATE OR REPLACE PACKAGE BODY ACTIONS.initiative_reporting_pkg
IS

PROCEDURE GetTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, active,
		       pct_lower_tolerance, pct_upper_tolerance, tolerance_type, measure_conversion_id
		  FROM ( 
		  	SELECT ind.ind_sid sid_id, ind.description, ind.ind_type, ind.measure_sid, ind.active, 
		  		CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name,
		  		ind.pct_lower_tolerance, ind.pct_upper_tolerance, ind.tolerance_type,
		  		SYS_CONNECT_BY_PATH(replace(ind.description,chr(1),'_'),'') path, umc.measure_conversion_id
			  FROM csr.v$ind ind
			  LEFT JOIN csr.user_measure_conversion umc ON ind.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   START WITH (in_include_root = 0 AND parent_sid = in_parent_sid) OR 
			 			  (in_include_root = 1 AND ind_sid = in_parent_sid)
				CONNECT BY PRIOR ind_sid = parent_sid
					ORDER SIBLINGS BY description
		)i, (
			SELECT DISTINCT ind_sid sid_id
			  FROM csr.ind
			 	START WITH ind_sid IN ( 
			 		SELECT ind_sid 
		              FROM (
						SELECT DISTINCT ind_sid, SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),'') path
		                  FROM csr.v$ind
		                 WHERE app_sid = in_app_sid
		                    START WITH ind_sid = in_parent_sid
		                    CONNECT BY PRIOR ind_sid = parent_sid
		            )
		            WHERE LOWER(path) LIKE '%'||LOWER(in_search_phrase)||'%'
			 	)
			 	CONNECT BY PRIOR parent_sid = ind_sid 
		)ti 
		WHERE i.sid_id = ti.sid_id 
		ORDER BY i.rn;
END;

PROCEDURE GetTreeTagFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_tag_group_count	IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, active,
		       pct_lower_tolerance, pct_upper_tolerance, tolerance_type, measure_conversion_id
		  FROM ( 
		  	SELECT ind.ind_sid sid_id, ind.description, ind.ind_type, ind.measure_sid, ind.active, 
		  		CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name,
		  		ind.pct_lower_tolerance, ind.pct_upper_tolerance, ind.tolerance_type, umc.measure_conversion_id
			  FROM csr.v$ind ind
			  LEFT JOIN csr.user_measure_conversion umc ON ind.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			    START WITH (in_include_root = 0 AND parent_sid = in_parent_sid) OR 
			 	 		   (in_include_root = 1 AND ind_sid = in_parent_sid)
				CONNECT BY PRIOR ind_sid = parent_sid
					ORDER SIBLINGS BY description
		)i, ( 
			SELECT DISTINCT ind_sid sid_id 
			  FROM csr.ind
			 	START WITH ind_sid IN (                
	                  SELECT ind_sid
	                    FROM (
	                    	SELECT ind_sid, set_id
	                      	  FROM csr.search_tag st, csr.ind_tag it
	                     	 WHERE st.tag_id = it.tag_id
	                      GROUP BY ind_sid, set_id
	                   )
	                  GROUP BY ind_sid
	                  HAVING count(*) = in_tag_group_count
		        )
			 	AND ind_sid IN ( 
			 		SELECT ind_sid 
		              FROM (
						SELECT DISTINCT ind_sid, SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),'') path
		                  FROM csr.v$ind
		                 WHERE app_sid = in_app_sid
		                    START WITH ind_sid = in_parent_sid
		                    CONNECT BY PRIOR ind_sid = parent_sid
		            )
		            WHERE LOWER(path) LIKE '%'||LOWER(in_search_phrase)||'%'
			 	)
			 	CONNECT BY PRIOR parent_sid = ind_sid
		)ti 
		WHERE i.sid_id = ti.sid_id 
		ORDER BY i.rn;
END;

PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT *
			  -- ************* N.B. that's a literal 0x1 character in there, not a space **************
			  FROM (SELECT i.ind_sid sid_id, 'CSRIndicator' class_name, i.description, i.ind_type, i.measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
			  			   i.pct_lower_tolerance, i.pct_upper_tolerance, i.tolerance_type,
			  			   SYS_CONNECT_BY_PATH(replace(i.description,chr(1),'_'),'') path, i.active,
			  			   umc.measure_conversion_id
					  FROM csr.v$ind i
					  LEFT JOIN csr.user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   START WITH (in_include_root = 0 AND parent_sid = in_parent_sid) OR 
						 			  (in_include_root = 1 AND ind_sid = in_parent_sid)
						   CONNECT BY PRIOR ind_sid = parent_sid
					 ORDER SIBLINGS BY description
			  )
			  WHERE (in_search_phrase IS NULL OR LOWER(path) LIKE '%'||LOWER(in_search_phrase)||'%')
		 )
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetListTagFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_tag_group_count	IN	NUMBER,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sid);
	END IF;
	
	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT *
			  FROM (SELECT i.ind_sid sid_id, 'CSRIndicator' class_name, i.description, i.ind_type, i.measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
			  			   i.pct_lower_tolerance, i.pct_upper_tolerance, i.tolerance_type,
			  			   SYS_CONNECT_BY_PATH(replace(i.description,chr(1),'_'),'') path, i.active,
			  			   rownum rn, umc.measure_conversion_id
					  FROM csr.v$ind i
					  LEFT JOIN csr.user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
						   START WITH (in_include_root = 0 AND parent_sid = in_parent_sid) OR 
						 			  (in_include_root = 1 AND ind_sid = in_parent_sid)
						   CONNECT BY PRIOR ind_sid = parent_sid
					 ORDER SIBLINGS BY description
			 )
			 WHERE (in_search_phrase IS NULL OR LOWER(path) LIKE '%'||LOWER(in_search_phrase)||'%')
			   AND sid_id IN (
	               SELECT ind_sid
	                 FROM (SELECT ind_sid, set_id
	                   	     FROM csr.search_tag st, csr.ind_tag it
	                 	    WHERE st.tag_id = it.tag_id
	                     GROUP BY ind_sid, set_id)
	                GROUP BY ind_sid
	               HAVING count(*) = in_tag_group_count
		      )
		      ORDER BY rn
	     )
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetMetricList(
	out_metrics						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_metrics FOR
		SELECT DISTINCT t.ind_template_id, t.name, t.description, t.input_label
		  FROM ind_template t, project_ind_template pit
		 WHERE t.app_sid = security_pkg.GetAPP
		   AND t.calculation IS NULL
		   AND pit.app_sid = security_pkg.GetAPP
		   AND pit.ind_template_id = t.ind_template_id
		   AND pit.update_per_period = 1
		   	ORDER BY t.description;
END;

PROCEDURE GetReportTemplateList (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT report_template_id, description
		  FROM periodic_report_template
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE GetReportTemplateXml (
	in_template_id				IN	periodic_report_template.report_template_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT report_template_id, description, template_xml
		  FROM periodic_report_template
		 WHERE app_sid = security_pkg.GetAPP
		   AND report_template_id = in_template_id;
END;

PROCEDURE PeriodicReport (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_statuses					IN	security_pkg.T_SID_IDS,
	out_task					OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_task_statuses				security.T_SID_TABLE;
	v_status_count				NUMBER;
BEGIN
	
	t_task_statuses := security_pkg.SidArrayToTable(in_statuses);
	
	SELECT COUNT(*)
	  INTO v_status_count
	  FROM (TABLE(t_task_statuses));
	
	OPEN out_task FOR
		SELECT 
			o.lvl, o.is_leaf, 
			pr.project_sid, pr.name project_name,
			t.task_sid, t.parent_task_sid, t.name task_name, 
			t.start_dtm, t.end_dtm, t.period_duration, t.fields_xml, 
			rgn.region_sid, m.region_desc,
		  	ts.task_status_id, ts.label task_status_label,
		  	m.actual_ind_template_id, m.actual_name, m.actual_description, m.actual_period, m.actual_ind_sid,
		  	m.forecast_ind_template_id, m.forecast_name, m.forecast_description, m.forecast_period, m.forecast_ind_sid,
			m.merged_ind_template_id, m.merged_name, m.merged_description, m.merged_period, m.merged_ind_sid,
			m.ongoing_ind_template_id, m.ongoing_name, m.ongoing_description, m.ongoing_period, m.ongoing_ind_sid,
			rgn.region_sid_path, rgn.region_desc_path
		  FROM task t, project pr, task_status ts, (
		  	SELECT
          		pr.project_sid, t.task_sid,
			  	tr.region_sid, rgn.description region_desc,
			  	--
			  	actual_it.ind_template_id actual_ind_template_id, 
			  	actual_it.name actual_name, 
			  	actual_it.description actual_description,
			  	actual_it.per_period_duration actual_period, 
			  	actual_inst.ind_sid actual_ind_sid,
			  	--
			  	forecast_it.ind_template_id forecast_ind_template_id,
			  	forecast_it.name forecast_name, 
			  	forecast_it.description forecast_description, 
			  	forecast_it.per_period_duration forecast_period, 
			  	forecast_inst.ind_sid forecast_ind_sid,
			  	--
			  	merged_it.ind_template_id merged_ind_template_id, 
			  	merged_it.name merged_name, 
			  	merged_it.description merged_description, 
			  	merged_it.per_period_duration merged_period,
			  	merged_inst.ind_sid merged_ind_sid,
			  	--
			  	ongoing_it.ind_template_id ongoing_ind_template_id, 
			  	ongoing_it.name ongoing_name, 
			  	ongoing_it.description ongoing_description, 
			  	ongoing_it.per_period_duration ongoing_period,
			  	ongoing_inst.ind_sid ongoing_ind_sid
			  	--
			  FROM task t
				  JOIN project pr 
		      	  	ON pr.project_sid = t.project_sid
				  LEFT JOIN task_region tr 
				  	ON tr.task_sid = t.task_sid
		      	  LEFT JOIN csr.v$region rgn 
		      	  	ON tr.region_sid = rgn.region_sid
		      	  --
		      	  JOIN task_ind_template_instance actual_inst 
		      	  	ON actual_inst.task_sid = t.task_sid
		      	  JOIN ind_template actual_it 
		      	  	ON actual_it.ind_template_id = actual_inst.from_ind_template_id
		      	  JOIN project_ind_template actual_pit 
		      	  	ON actual_pit.project_sid = t.project_sid 
		      	   AND actual_pit.ind_template_id = actual_it.ind_template_id 
		      	   AND actual_pit.update_per_period = 1
		      	  --
              	  LEFT JOIN task_ind_template_instance forecast_inst 
		      	  	ON t.task_sid = forecast_inst.task_sid
               	   AND forecast_inst.from_ind_template_id = actual_pit.saving_template_id
               	  LEFT JOIN ind_template forecast_it
                 	ON forecast_inst.from_ind_template_id = forecast_it.ind_template_id
              	  --
		      	  LEFT JOIN task_ind_template_instance merged_inst 
		      	  	ON t.task_sid = merged_inst.task_sid
               	   AND merged_inst.from_ind_template_id = actual_pit.merged_template_id
              	  LEFT JOIN ind_template merged_it
                	ON merged_inst.from_ind_template_id = merged_it.ind_template_id
              	  --
		      	  LEFT JOIN task_ind_template_instance ongoing_inst 
		      	  	ON t.task_sid = ongoing_inst.task_sid
               	   AND ongoing_inst.from_ind_template_id = actual_pit.ongoing_template_id
              	  LEFT JOIN ind_template ongoing_it
                	ON ongoing_inst.from_ind_template_id = ongoing_it.ind_template_id
		) m, (
			SELECT /*+ALL_ROWS*/ 
				ROWNUM rn, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, task_sid
			  FROM task
			 START WITH parent_task_sid IS NULL
			 CONNECT BY PRIOR task_sid = parent_task_sid
		) o, (
			SELECT /*+ALL_ROWS*/
				region_sid,
				SYS_CONNECT_BY_PATH(region_sid, '\\') region_sid_path,
				SYS_CONNECT_BY_PATH(description, '\\') region_desc_path
			  FROM csr.v$region
			 	START WITH region_sid = in_region_sid
			 	CONNECT BY PRIOR region_sid = parent_sid
		) rgn
		 WHERE pr.project_sid = t.project_sid
       	   AND t.task_sid = o.task_sid 
		   AND ts.task_status_id = t.task_status_id
		   AND m.task_sid(+) = t.task_sid
		   AND rgn.region_sid(+) = m.region_sid
		   -- Only filter at the leaf node level
		   AND (v_status_count = 0 OR o.is_leaf = 0 OR t.task_status_id IN (SELECT column_value FROM TABLE(t_task_statuses)))
		   AND (o.is_leaf = 0 OR m.region_sid = rgn.region_sid)
		   	ORDER BY o.rn, pr.name, t.name, m.region_desc, m.region_sid, m.actual_description, m.actual_ind_sid
		;
		
	OPEN out_tags FOR
		SELECT t.task_sid, tg.tag_group_id, tg.name, tag.tag_id, tag.tag, tag.explanation
		  FROM task t
		  	JOIN task_tag tt ON tt.task_sid = t.task_sid
		  	JOIN tag ON tag.tag_id = tt.tag_id
		  	JOIN tag_group_member tgm ON tgm.tag_id = tag.tag_id
		  	JOIN tag_group tg ON tg.tag_group_id = tgm.tag_group_id
		  		ORDER BY t.task_sid, tg.label, tg.tag_group_id, tag.tag, tag.tag_id
		;
END;


END initiative_reporting_pkg;
/
