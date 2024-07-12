CREATE OR REPLACE PACKAGE BODY CSR.scenario_run_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Should be called via the Create method
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	UPDATE customer
	   SET merged_scenario_run_sid = DECODE(merged_scenario_run_sid, in_sid_id, NULL, merged_scenario_run_sid),
	       unmerged_scenario_run_sid = DECODE(unmerged_scenario_run_sid, in_sid_id, NULL, unmerged_scenario_run_sid)
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM calc_job_ind
	 WHERE app_sid = v_app_sid
	   AND calc_job_id IN (
	   		SELECT calc_job_id
	   		  FROM calc_job
	   		 WHERE app_sid = v_app_sid
	   		   AND scenario_run_sid = in_sid_id
	  );

	DELETE FROM calc_job_aggregate_ind_group
	 WHERE app_sid = v_app_sid
	   AND calc_job_id IN (
	   		SELECT calc_job_id
	   		  FROM calc_job
	   		 WHERE app_sid = v_app_sid
	   		   AND scenario_run_sid = in_sid_id
	  );

	DELETE FROM calc_job_fetch_stat
	 WHERE app_sid = v_app_sid 
	   AND calc_job_id IN (SELECT calc_job_id 
							 FROM calc_job_stat
							WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id);
	
	DELETE FROM calc_job_stat
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;
	
	DELETE FROM calc_job
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;

	DELETE FROM scenario_run_val
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;

	UPDATE metric_dashboard_ind
	   SET absol_view_scenario_run_sid = NULL
	 WHERE app_sid = v_app_sid
	   AND absol_view_scenario_run_sid = in_sid_id;

	UPDATE metric_dashboard_ind
	   SET inten_view_scenario_run_sid = NULL
	 WHERE app_sid = v_app_sid
	   AND inten_view_scenario_run_sid = in_sid_id;

	UPDATE benchmark_dashboard_ind
	   SET scenario_run_sid = NULL
	 WHERE app_sid = v_app_sid
	   AND scenario_run_sid = in_sid_id;

	DELETE FROM dataview_scenario_run
	 WHERE app_sid = v_app_sid
	   AND scenario_run_sid = in_sid_id;

	UPDATE img_chart
	   SET scenario_run_sid = NULL,
		   scenario_run_type = 0
	 WHERE app_sid = v_app_sid 
	   AND scenario_run_sid = in_sid_id;

	UPDATE scenario
	   SET auto_update_run_sid = null
	 WHERE app_sid = v_app_sid 
	   AND auto_update_run_sid = in_sid_id;
	
	DELETE FROM scenario_run
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN	security_pkg.T_SID_ID
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	NULL;
END;

PROCEDURE SetValue(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_period_start					IN	scenario_run_val.period_start_dtm%TYPE,
	in_period_end					IN	scenario_run_val.period_end_dtm%TYPE,
	in_val_number					IN	scenario_run_val.val_number%TYPE,
	in_source_type_id				IN	scenario_run_val.source_type_id%TYPE DEFAULT 0,
	in_error_code					IN	scenario_run_val.error_code%TYPE DEFAULT NULL
)
AS
	v_divisibility					ind.divisibility%TYPE;
	v_rounded_in_val_number			scenario_run_val.val_number%TYPE;
	v_pct_ownership					NUMBER;
	v_scaled_val_number				scenario_run_val.val_number%TYPE;
BEGIN
	SELECT NVL(i.divisibility, m.divisibility)
	  INTO v_divisibility
	  FROM ind i, measure m
	 WHERE i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
	   AND i.ind_sid = in_ind_sid;

	-- round it as we'll put it in the database, and apply pctOwnership so long
	-- as we're not aggregating
--	IF in_source_type_id = csr_data_pkg.SOURCE_TYPE_AGGREGATOR AND bitand(in_update_flags, IND_CASCADE_PCT_OWNERSHIP) = 0 THEN
        v_rounded_in_val_number := ROUND(in_val_number, 10);
--	ELSE
--		v_pct_ownership := region_pkg.getPctOwnership(in_ind_sid, in_region_sid, in_period_start);
--        v_rounded_in_val_number := ROUND(in_val_number * v_pct_ownership, 10);
--    END IF;
    
    -- clear or scale any overlapping values (we scale for stored calcs / aggregates, but clear for other value types)
    -- there are multiple cases, but basically it boils down to having a non-overlapping left/right portion or the value being completely covered
    -- for the left/right cases we either scale according to divisibility or create NULLs covering the non-overlapping portion 
    -- (to clear aggregates up the tree in those time periods)
    -- for the complete coverage case the old value simply needs to be removed (but any value with the exact period is simply updated in place)
    --security_pkg.debugmsg('adding value for ind='||in_ind_sid||', region='||in_region_sid||',period='||in_period_start||' -> '||in_period_end);    
    FOR r IN (SELECT /*+index(scenario_run_val pk_scenario_run_val)*/ rowid rid, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id
    			FROM scenario_run_val
		       WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		         AND scenario_run_sid = in_scenario_run_sid
		         AND ind_sid = in_ind_sid
			     AND region_sid = in_region_sid
			     AND period_end_dtm > in_period_start
			     AND period_start_dtm < in_period_end
			     AND NOT (period_start_dtm = in_period_start AND period_end_dtm = in_period_end)
			     	 FOR UPDATE) LOOP
		
		-- non-overlapping portion on the left
		IF r.period_start_dtm < in_period_start THEN
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) THEN
				IF v_divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
				END IF;

				--security_pkg.debugmsg('adding left value from '||r.period_start_dtm||' to '||in_period_start||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');				
				INSERT INTO scenario_run_val
					(scenario_run_sid, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id)
				VALUES
					(in_scenario_run_sid, in_ind_sid, in_region_sid, r.period_start_dtm, in_period_start, v_scaled_val_number, 
					 r.error_code, r.source_type_id);
			END IF;
		END IF;

		-- non-overlapping portion on the right
		IF r.period_end_dtm > in_period_end THEN
			
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) THEN
				IF v_divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
				END IF;

				--security_pkg.debugmsg('adding right value from '||in_period_end||' to '||r.period_end_dtm||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');
				INSERT INTO scenario_run_val
					(scenario_run_sid, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id)
				VALUES
					(in_scenario_run_sid, in_ind_sid, in_region_sid, in_period_end, r.period_end_dtm, v_scaled_val_number, 
					 r.error_code, r.source_type_id);
			END IF;
		END IF;
		
		-- remove the overlapping value
		DELETE FROM scenario_run_val
		 WHERE rowid = r.rid;
	END LOOP;
			  
    -- upsert (there are constraints on val which will throw DUP_VAL_ON_INDEX if this should be an update)
    BEGIN
        INSERT INTO scenario_run_val (scenario_run_sid, ind_sid, region_sid, period_start_dtm,
            period_end_dtm,  val_number, source_type_id, error_code)
        VALUES (in_scenario_run_sid, in_ind_sid, in_region_sid, in_period_start,
            in_period_end, v_rounded_in_val_number, in_source_type_id, in_error_code);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
        	UPDATE scenario_run_val
        	   SET val_number = v_rounded_in_val_number,
        	   	   source_type_id = in_source_type_id,
        	   	   error_code = in_error_code
        	 WHERE scenario_run_sid = in_scenario_run_sid
        	   AND ind_sid = in_ind_sid
        	   AND region_sid = in_region_sid
        	   AND period_start_dtm = in_period_start
        	   AND period_end_dtm = in_period_end;
    END;
END;

PROCEDURE CreateScenarioRun(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario_run.description%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE
)
AS
	v_parent_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT parent_sid_id
	  INTO v_parent_sid
	  FROM security.securable_object
	 WHERE sid_id = in_scenario_sid;
	 
	securableObject_pkg.CreateSO(security_pkg.GetACT(), v_parent_sid,
		class_pkg.GetClassId('CSRScenarioRun'), null, out_scenario_run_sid);
		
	INSERT INTO scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (out_scenario_run_sid, in_scenario_sid, in_description);
END;


-- NESTLE HACK
PROCEDURE RefreshData(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_run_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the scenario run with sid '||in_scenario_run_sid);
	END IF;
	
	UPDATE scenario_run SET run_dtm = SYSDATE WHERE scenario_run_sid = in_scenario_run_sid;
END;

PROCEDURE GetDetails(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_run_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the scenario run with sid '||in_scenario_run_sid);
	END IF;

	OPEN out_cur FOR
		SELECT sr.scenario_sid, sr.run_dtm, sr.description run_description, s.description, sr.last_success_dtm, s.file_based
		  FROM scenario_run sr
		  LEFT JOIN scenario s ON sr.scenario_sid = s.scenario_sid
		 WHERE sr.scenario_run_sid = in_scenario_run_sid;
END;

-- No security: only used by scrag++'s analysisServer
PROCEDURE GetFeatureFlags(
	in_app_sid						IN	scenario_run.app_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT	feature_flag_scrag_a,
				feature_flag_scrag_b,
				feature_flag_scrag_c
		  FROM customer_feature_flags
		 WHERE app_sid = in_app_sid;
END;

-- No security: only used by scrag++'s analysisServer
PROCEDURE GetScenarioRunFile(
	in_app_sid						IN	scenario_run.app_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,	
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT srvf.file_path, srvf.sha1, srvf.version, s.equality_epsilon,
				NVL(feature_flag_scrag_a,0) feature_flag_scrag_a,
				NVL(feature_flag_scrag_b,0) feature_flag_scrag_b,
				NVL(feature_flag_scrag_c,0) feature_flag_scrag_c
		  FROM scenario s, scenario_run sr, scenario_run_version_file srvf
		  LEFT JOIN customer_feature_flags cff ON cff.app_sid = srvf.app_sid
		 WHERE srvf.app_sid = in_app_sid AND srvf.scenario_run_sid = in_scenario_run_sid
		   AND s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
		   AND sr.app_sid = srvf.app_sid AND sr.scenario_run_sid = srvf.scenario_run_sid 
		   AND sr.version = srvf.version;
END;

PROCEDURE IsFileBased(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	out_file_based					OUT	scenario.file_based%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_run_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the scenario run with sid '||in_scenario_run_sid);
	END IF;
	
	SELECT s.file_based
	  INTO out_file_based
	  FROM scenario_run sr, scenario s
	 WHERE sr.scenario_run_sid = in_scenario_run_sid
	   AND sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid;
END;

PROCEDURE GetFileBasedScenarioRuns(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	
	OPEN out_cur FOR
		SELECT sr.scenario_run_sid, sr.description
		  FROM scenario_run sr
		  JOIN scenario s ON sr.scenario_sid = s.scenario_sid
		 WHERE file_based = 1
		   AND sr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAggregateDetails(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_start_dtm					IN	scenario_run_val.period_start_dtm%TYPE,
	in_end_dtm						IN	scenario_run_val.period_end_dtm%TYPE,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_child_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN	
	-- check we have read permission on indicator + region
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;

	-- get this value
	OPEN out_val_cur FOR 
		SELECT /*+ALL_ROWS*/ srv.ind_sid, srv.region_sid, srv.period_start_dtm, srv.period_end_dtm,
			   srv.val_number, srv.error_code, srv.source_type_id, srv.source_id			   
	      FROM scenario_run_val srv,
	  		   (SELECT region_sid
	  	          FROM region 
		   	           START WITH region_sid = in_region_sid
	                   CONNECT BY PRIOR parent_sid = region_sid
	             UNION
	            SELECT NVL(link_to_region_sid, region_sid) region_sid
	              FROM region
	             WHERE parent_sid = in_region_sid) r
	     WHERE srv.scenario_run_sid = in_scenario_run_sid
	       AND r.region_sid = srv.region_sid
	       AND srv.period_end_dtm > in_start_dtm
	       AND srv.period_start_dtm < in_end_dtm
	       AND srv.ind_sid = in_ind_sid
		 ORDER BY srv.ind_sid, srv.region_sid, srv.period_start_dtm;
	       
	OPEN out_child_cur FOR
		SELECT NVL(link_to_region_sid, region_sid) region_sid,
			   DECODE(link_to_region_sid, NULL, 0, 1) is_link
		  FROM region
		 WHERE parent_sid = in_region_sid;
END;

PROCEDURE GetBaseDataForIndFiltered(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_region 			IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ srv.ind_sid, srv.region_sid, srv.period_start_dtm, srv.period_end_dtm,
			   srv.val_number, srv.error_code, srv.source_type_id, srv.source_id			   
		  FROM scenario_run_val srv
		 WHERE srv.scenario_run_sid = in_scenario_run_sid
		   AND srv.ind_sid = in_ind_sid
		   AND (srv.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL)
		   AND srv.period_end_dtm > in_from_dtm
		   AND (in_get_aggregates = 1 OR srv.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND (in_get_stored_calc_values = 1 OR srv.source_type_id != csr_data_pkg.SOURCE_TYPE_STORED_CALC)
		   AND srv.region_sid IN (SELECT region_sid 
		   						    FROM region 
		   						  	     START WITH region_sid = in_filter_by_region
		   						  	     CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid)
		 ORDER BY srv.ind_sid, srv.region_sid, srv.period_start_dtm;
END;

PROCEDURE GetBaseDataForRegionFiltered(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_ind   				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ srv.ind_sid, srv.region_sid, srv.period_start_dtm, srv.period_end_dtm,
			   srv.val_number, srv.error_code, srv.source_type_id, srv.source_id
		  FROM scenario_run_val srv
		 WHERE srv.scenario_run_sid = in_scenario_run_sid
		   AND srv.region_sid = in_region_sid 
		   AND (srv.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL)
		   AND srv.period_end_dtm > in_from_dtm
		   AND (in_get_aggregates = 1 OR srv.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND (in_get_stored_calc_values = 1 OR srv.source_type_id != csr_data_pkg.SOURCE_TYPE_STORED_CALC)
		   AND srv.ind_sid IN (SELECT ind_sid 
		   					     FROM ind 
		   					   		  START WITH ind_sid = in_filter_by_ind 
		   					   		  CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid)
		 ORDER BY srv.ind_sid, srv.region_sid, srv.period_start_dtm;
END;

PROCEDURE GetBaseDataFiltered(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF in_ind_or_region = 'region' THEN
		GetBaseDataForRegionFiltered(in_scenario_run_sid, in_sid, in_from_dtm, in_to_dtm,
			 in_filter_by, in_get_aggregates, in_get_stored_calc_values, out_cur);
	ELSE
		GetBaseDataForIndFiltered(in_scenario_run_sid, in_sid, in_from_dtm, in_to_dtm,
			in_filter_by, in_get_aggregates, in_get_stored_calc_values, out_cur);
	END IF;
END;

-- No security: only used by scrag++'s analysisServer
PROCEDURE GetDelegationIndsAndRegions(
	in_app_sid						IN	sheet.app_sid%TYPE,
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
)
AS
	v_sheet_table					security.T_SID_TABLE;
BEGIN
	v_sheet_table := security_pkg.SidArrayToTable(in_sheet_ids);
	
	OPEN out_ind_cur FOR
		SELECT di.ind_sid
		  FROM sheet s, delegation_ind di, TABLE(v_sheet_table) sl
		 WHERE s.app_sid = di.app_sid AND s.delegation_sid = di.delegation_sid
		   AND s.app_sid = in_app_sid AND sl.column_value = s.sheet_id;

	OPEN out_region_cur FOR
		SELECT dr.region_sid
		  FROM sheet s, delegation_region dr, TABLE(v_sheet_table) sl
		 WHERE s.app_sid = dr.app_sid AND s.delegation_sid = dr.delegation_sid
		   AND s.app_sid = in_app_sid AND sl.column_value = s.sheet_id;
END;

-- No security: only used by scrag++'s analysisServer
PROCEDURE GetSheetValues(
	in_app_sid						IN	sheet.app_sid%TYPE,
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	in_ind_sids						IN	security_pkg.T_SID_IDS,	
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_start_dtm					OUT	sheet.start_dtm%TYPE,
	out_end_dtm						OUT	sheet.end_dtm%TYPE,
    out_val_cur						OUT	SYS_REFCURSOR
)
AS
	v_sheet_table					security.T_SID_TABLE;
	v_inds_table					security.T_SID_TABLE;
	v_regions_table					security.T_SID_TABLE;
BEGIN
	v_sheet_table := security_pkg.SidArrayToTable(in_sheet_ids);
	v_inds_table := security_pkg.SidArrayToTable(in_ind_sids);
	v_regions_table := security_pkg.SidArrayToTable(in_region_sids);

	SELECT MIN(s.start_dtm) start_dtm, MAX(s.end_dtm) end_dtm
	  INTO out_start_dtm, out_end_dtm
	  FROM sheet s, TABLE(v_sheet_table) sl
	 WHERE sl.column_value = s.sheet_id;

	OPEN out_val_cur FOR
		SELECT s.start_dtm period_start_dtm, s.end_dtm period_end_dtm, 1 source, sv.sheet_value_id,
			   0 source_type_id, di.ind_sid, dr.region_sid, sv.val_number, null error_code,
			   sv.set_dtm changed_dtm, sv.note, 0 is_merged
		  FROM delegation_ind di, delegation_region dr, delegation d, sheet s, sheet_value sv,
		       TABLE(v_sheet_table) sl, ind i, TABLE(v_inds_table) il, TABLE(v_regions_table) rl
		 WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.delegation_sid
		   AND d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
		   AND sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
		   AND sv.app_sid = di.app_sid AND sv.ind_sid = di.ind_sid
		   AND sv.app_sid = dr.app_sid AND sv.region_sid = dr.region_sid
		   AND sv.ind_sid = il.column_value
		   AND sv.region_sid = rl.column_value
		   AND s.app_sid = in_app_sid AND s.sheet_id = sl.column_value
		   AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
		   AND i.measure_sid IS NOT NULL
		   AND i.ind_type IN (csr_data_pkg.IND_TYPE_NORMAL, csr_data_pkg.IND_TYPE_AGGREGATE)		   
		 ORDER BY di.ind_sid, dr.region_sid, s.start_dtm;
END;

END scenario_run_pkg;
/
