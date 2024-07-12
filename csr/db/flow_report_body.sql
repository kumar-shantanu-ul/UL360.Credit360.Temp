CREATE OR REPLACE PACKAGE BODY CSR.flow_report_pkg AS

FUNCTION CleanLabel (
	in_label	VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	RETURN SUBSTR(
			REGEXP_REPLACE(
				REGEXP_REPLACE(in_label, '( *[[:punct:]])', ' '),
				'( ){2,}',
				' '),
			 1, 255);
END;

FUNCTION CleanLookupKey (
	in_label	VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	RETURN UPPER(REPLACE(CleanLabel(in_label), ' ', '_'));
END;

PROCEDURE GetOrCreateAggregateInd (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_parent_ind_sid			IN	ind.parent_sid%TYPE,
	in_name						IN	ind.name%TYPE,
	in_desc						IN	ind_description.description%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE,
	in_divisibility				IN	ind.divisibility%TYPE,
	in_measure_sid				IN	ind.measure_sid%TYPE,
	out_ind_sid					OUT	ind.ind_sid%TYPE
)
AS
	v_ind_sid					ind.ind_sid%TYPE;
BEGIN
	BEGIN
		-- Search by parent SID and name. Using lookup keys could return indicators for other workflows
		v_ind_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'APP'), in_parent_ind_sid, in_name);
		
		indicator_pkg.EnableIndicator(
			in_ind_sid				=> v_ind_sid
		);

	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> in_parent_ind_sid,
				in_name 				=> in_name,
				in_lookup_key			=> in_lookup_key,
				in_description 			=> in_desc,
				in_active	 			=> 1,
				in_ind_type				=> csr_data_pkg.IND_TYPE_AGGREGATE,
				in_measure_sid			=> in_measure_sid,
				in_divisibility			=> in_divisibility,
				in_aggregate			=> 'SUM',
				in_is_system_managed	=> 1,
				out_sid_id				=> v_ind_sid
			);
	END;

	BEGIN
		INSERT INTO aggregate_ind_group_member(aggregate_ind_group_id, ind_sid)
		VALUES (in_aggregate_ind_group_id, v_ind_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	out_ind_sid := v_ind_sid;
END;

PROCEDURE RecordTimeInFlowStates(
	in_flow_sid			IN flow.flow_sid%TYPE,
	in_parent_ind_sid	IN ind.parent_sid%TYPE,
	in_recalc_all		IN NUMBER DEFAULT 0
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('security', 'app');
	v_act_id					security.security_pkg.T_ACT_ID := SYS_CONTEXT('security', 'act');
	v_trash_sid					security.security_pkg.T_SID_ID;
	v_flow_sid					flow.flow_sid%TYPE;
	v_flow_ct_lookup			flow.label%TYPE;
	v_flow_ct_sid				flow.flow_sid%TYPE;
	v_flow_alert_class			flow.flow_alert_class%TYPE;
	v_cms_oracle_tab_sid		cms.tab.tab_sid%TYPE;
	v_cms_oracle_schema			cms.tab.oracle_schema%TYPE;
	v_cms_oracle_table			cms.tab.oracle_table%TYPE;
	v_hours_measure_sid			security.security_pkg.T_SID_ID;
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_aggregate_group_name		aggregate_ind_group.name%TYPE;
	v_aggregate_group_label		aggregate_ind_group.label%TYPE;
	v_aggregate_group_proc		aggregate_ind_group.helper_proc%TYPE;
	v_aggregate_name_check		aggregate_ind_group.name%TYPE;
	v_ind_sid					security.security_pkg.T_SID_ID;
	v_check						NUMBER(10) := 0;
BEGIN
	SELECT trash_sid
	  INTO v_trash_sid
	  FROM customer
	 WHERE app_sid = v_app_sid;

	-- 1) Make sure workflow is not in trash
	-- 2) Check we support standard statistics aggregation for this type of workflow
	-- 3) Check the workflow hasn't already been assigned a different aggregate group
	SELECT f.flow_sid, CleanLookupKey(f.label), f.flow_alert_class, f.aggregate_ind_group_id, a.name
	  INTO v_flow_sid, v_flow_ct_lookup, v_flow_alert_class, v_aggregate_ind_group_id, v_aggregate_name_check
	  FROM flow f
	  JOIN security.securable_object so ON f.flow_sid = so.sid_id
 LEFT JOIN aggregate_ind_group a ON f.aggregate_ind_group_id = a.aggregate_ind_group_id
	 WHERE f.flow_sid = in_flow_sid
	   AND f.app_sid = v_app_sid
	   AND so.parent_sid_id <> v_trash_sid
	   AND f.flow_alert_class IS NOT NULL;

	-- Set standard aggregations for each flow type. Easy to override if client wants a bespoke queries
	CASE v_flow_alert_class
		WHEN 'supplier' THEN
			v_aggregate_group_name := 'SUPPLIER_FLOW_STATS_' || TO_CHAR(in_flow_sid);
			v_aggregate_group_proc := 'csr.flow_report_pkg.GetSupplierFlowValues';
			v_aggregate_group_label := 'Supplier workflow statistics';

		WHEN 'campaign' THEN
			v_aggregate_group_name := 'CAMPAIGN_FLOW_STATS_' || TO_CHAR(in_flow_sid);
			v_aggregate_group_proc := 'csr.flow_report_pkg.GetCampaignFlowValues';
			v_aggregate_group_label := 'Campaign workflow statistics';

		WHEN 'cms' THEN
			-- Get table name from CMS stats.
			SELECT tab_sid, oracle_schema, oracle_table
			  INTO v_cms_oracle_tab_sid, v_cms_oracle_schema, v_cms_oracle_table
			  FROM cms.tab
			 WHERE flow_sid = in_flow_sid;

			v_aggregate_group_name := 'CMS_FLOW_STATS_' || TO_CHAR(v_cms_oracle_tab_sid);
			v_aggregate_group_proc := 'cms.tab_pkg.GetCmsTableFlowValues';
			v_aggregate_group_label := 'CMS workflow statistics ' || v_cms_oracle_schema || '.' || v_cms_oracle_table || ' (' || v_cms_oracle_tab_sid || ')';

		ELSE
			RAISE_APPLICATION_ERROR(ERR_AGGREGATION_DOESNT_EXIST, 'Workflow stats aggregation does not exist for type: "' || v_flow_alert_class || '".');

	END CASE;

	IF v_aggregate_ind_group_id IS NULL THEN
		INSERT INTO aggregate_ind_group (aggregate_ind_group_id, name, label, helper_proc, run_daily, run_for_current_month)
		VALUES (aggregate_ind_group_id_seq.NEXTVAL, v_aggregate_group_name, v_aggregate_group_label, v_aggregate_group_proc, 1, 1)
		RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;
		
		UPDATE flow
		   SET aggregate_ind_group_id = v_aggregate_ind_group_id
		 WHERE flow_sid = in_flow_sid;
	ELSE
		-- Check there isn't already a DIFFERENT aggregation linked to this workflow
		IF v_aggregate_name_check <> v_aggregate_group_name THEN
			RAISE_APPLICATION_ERROR(ERR_AGGREGATE_GROUP_CLASH, 'Workflow already has aggregation group: "' || v_aggregate_name_check || '". This must be removed before a new one can be assigned.');
		END IF;
	END IF;
	
	-- Get/Make container for Workflow
	BEGIN
		v_flow_ct_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, in_parent_ind_sid, v_flow_ct_lookup);
		
		indicator_pkg.EnableIndicator(
			in_ind_sid				=> v_flow_ct_sid
		);
		
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> in_parent_ind_sid,
				in_name 				=> v_flow_ct_lookup,
				in_description 			=> v_flow_ct_lookup,
				in_active	 			=> 1,
				out_sid_id				=> v_flow_ct_sid
			);
	END;
	
	-- Get/create 'Time' measure
	BEGIN
		SELECT measure_sid
		  INTO v_hours_measure_sid
		  FROM measure
		 WHERE lookup_key = 'TIME_IN_HOURS'
		   AND app_sid = v_app_sid;
	EXCEPTION
		WHEN no_data_found THEN
			measure_pkg.CreateMeasure(
				in_name					=> 'Hours',
				in_description			=> 'Time measured in hours',
				in_divisibility			=> csr_data_pkg.DIVISIBILITY_DIVISIBLE,
				in_lookup_key			=> 'TIME_IN_HOURS',
				out_measure_sid			=> v_hours_measure_sid
			);
	END;
	
	FOR r IN (
		SELECT fs.flow_state_id, fs.label, 
			   flow_report_pkg.CleanLabel(fs.label) clean_desc,
			   flow_report_pkg.CleanLookupKey(fs.label) clean_name,
			   time_spent_ind_sid
		  FROM flow_state fs
		 WHERE fs.app_sid = v_app_sid
		   AND fs.flow_sid = in_flow_sid
		   AND is_deleted = 0
		   AND is_final = 0
		   AND time_spent_ind_sid IS NULL
	  ORDER BY pos ASC
	)
	LOOP
		-- Make indicators for each state in workflow
		GetOrCreateAggregateInd(
			in_aggregate_ind_group_id 	=> v_aggregate_ind_group_id,
			in_parent_ind_sid			=> v_flow_ct_sid,
			in_name						=> r.clean_name,
			in_desc						=> r.clean_desc,
			in_lookup_key				=> r.clean_name,
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_DIVISIBLE,
			in_measure_sid				=> v_hours_measure_sid,
			out_ind_sid					=> v_ind_sid
		);
		
		UPDATE flow_state
		   SET time_spent_ind_sid = v_ind_sid
		 WHERE flow_state_id = r.flow_state_id;
		 
		v_check := v_check + 1;
	END LOOP;
	
	IF v_check > 0 AND in_recalc_all = 1 THEN
		calc_pkg.AddJobsForAggregateIndGroup(v_aggregate_ind_group_id);
	END IF;
END;

/* PROCEDURES TO GET AGGREGATE VALUES */

/*	Each type of workflow has to populate temp_flow_item_region with flow_item_id and region SID
	then they can call this procedure to get the time spent in the workflow states 
*/
PROCEDURE INTERNAL_GetFlowStateValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	values_cur					OUT security.security_pkg.T_OUTPUT_CUR
)
AS
	v_date		DATE;
	v_sysdate	DATE := getSysDate;
	v_app_sid	security.security_pkg.T_SID_ID := SYS_CONTEXT('security', 'app');
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetIndicatorValues');
	END IF;

	DELETE FROM temp_dates;
	-- Use temp table of montly report period + final date as today to help us calculate the time
	v_date := ADD_MONTHS(in_start_dtm, 1);

	WHILE v_date <= ADD_MONTHS(in_end_dtm, 1) AND v_date <= ADD_MONTHS(v_sysdate, 1) LOOP
		INSERT INTO temp_dates (column_value, eff_date)
		VALUES (v_date, CASE WHEN v_date > v_sysdate THEN v_sysdate ELSE v_date END);
		v_date := ADD_MONTHS(v_date, 1);
	END LOOP;

	-- Populate Temp Region table so we can aggregate up the tree
	DELETE FROM temp_region_tree;

	-- get primary regions and all their children - this is to return
	-- data pre-aggregated up the region_tree (as issues created at mid-levels
	-- would otherwise act as blockers). Secondary tree aggregation works as normal
	INSERT INTO temp_region_tree (root_region_sid, child_region_sid)
	SELECT CONNECT_BY_ROOT region_sid, region_sid
	  FROM region
	 START WITH region_sid IN 
						(
						SELECT region_sid 
						  FROM region
						 WHERE app_sid = v_app_sid
					START WITH region_sid IN (SELECT region_tree_root_sid FROM region_tree WHERE is_primary=1) 
			  CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
						)
	CONNECT BY PRIOR app_sid = app_sid AND prior region_sid = parent_sid;

	OPEN values_cur FOR
		SELECT ind_sid, region_sid, hours_spent val_number, period_start_dtm,
			   ADD_MONTHS(period_start_dtm, 1) period_end_dtm, 
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id,
			   NULL error_code
		  FROM (
			SELECT f.time_spent_ind_sid ind_sid, trt.root_region_sid region_sid, 
					   TRUNC(SUM(f.post_set_dtm - f.set_dtm) * 24) hours_spent,
					   ADD_MONTHS(f.period_date, -1) period_start_dtm
				  FROM (
						  SELECT fsl.flow_state_log_id,
								 fsl.flow_item_id,
								 fsl.flow_state_id,
								 GREATEST(fsl.set_dtm, ADD_MONTHS(td.column_value, -1)) set_dtm,
								 fslpost.set_dtm next_set_dtm,
								 NVL(fslpost.set_dtm, td.eff_date) post_set_dtm, 
								 td.column_value period_date,
								 fi.last_flow_state_log_id,
								 fs.is_deleted,
								 fs.is_final,
								 fs.time_spent_ind_sid,
								 ROW_NUMBER() OVER (PARTITION BY fsl.flow_item_id, fsl.set_dtm, fsl.flow_state_id ORDER BY fslpost.set_dtm, td.eff_date) rn
							FROM flow_state_log fsl
							JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id
							JOIN aggregate_ind_group_member am
									 ON am.ind_sid = fs.time_spent_ind_sid
									AND am.aggregate_ind_group_id = in_aggregate_ind_group_id
							JOIN temp_dates td ON fsl.set_dtm < td.eff_date
					   LEFT JOIN flow_state_log fslpost
									 ON fslpost.flow_item_id = fsl.flow_item_id
									AND fslpost.set_dtm > fsl.set_dtm
									AND fslpost.set_dtm < td.eff_date
					   LEFT JOIN flow_item fi ON fi.flow_item_id = fsl.flow_item_id AND fsl.flow_state_log_id = fi.last_flow_state_log_id
						   WHERE fsl.app_sid = v_app_sid
						) f
				  JOIN temp_flow_item_region tfir ON tfir.flow_item_id = f.flow_item_id
				  JOIN temp_region_tree trt ON tfir.region_sid = trt.child_region_sid
				 WHERE f.is_deleted = 0
				   AND f.is_final = 0
				   AND (f.rn = 1 
						OR (f.rn > 1 AND f.next_set_dtm IS NULL)
						OR (f.rn > 1 AND f.flow_state_log_id = f.last_flow_state_log_id)
						)
			  GROUP BY f.time_spent_ind_sid, trt.root_region_sid, f.period_date
			  )
	 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

PROCEDURE GetSupplierFlowValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No special permissions required. Permission check made in INTERNAL_GetFlowStateValues.
	DELETE FROM temp_flow_item_region;

	INSERT INTO temp_flow_item_region (flow_item_id, region_sid) 
	SELECT sr.flow_item_id, s.region_sid
	  FROM flow f
	  JOIN flow_item fi ON f.flow_sid = fi.flow_sid
	  JOIN (
			SELECT supplier_company_sid, flow_item_id
			  FROM chain.supplier_relationship 
		  GROUP BY supplier_company_sid, flow_item_id
			) sr ON sr.flow_item_id = fi.flow_item_id
	  JOIN supplier s ON sr.supplier_company_sid = s.company_sid
	 WHERE f.app_sid = SYS_CONTEXT('security', 'app') 
	   AND f.aggregate_ind_group_id = in_aggregate_ind_group_id;

	INTERNAL_GetFlowStateValues(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		values_cur					=> out_cur
	);
END;

PROCEDURE GetCampaignFlowValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No special permissions required. Permission check made in INTERNAL_GetFlowStateValues.
	DELETE FROM temp_flow_item_region;

	INSERT INTO temp_flow_item_region (flow_item_id, region_sid) 
	SELECT fi.flow_item_id, rsr.region_sid
	  FROM flow f
	  JOIN flow_item fi ON f.flow_sid = fi.flow_sid
	  JOIN quick_survey_response qsr ON qsr.survey_response_id = fi.survey_response_id
	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
	 WHERE f.app_sid = SYS_CONTEXT('security', 'app') 
	   AND f.aggregate_ind_group_id = in_aggregate_ind_group_id;

	INTERNAL_GetFlowStateValues(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		values_cur					=> out_cur
	);
END;

END;
/
