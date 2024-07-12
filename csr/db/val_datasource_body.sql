CREATE OR REPLACE PACKAGE BODY CSR.val_datasource_pkg AS

PROCEDURE GetRegionTreeForSheets(
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_delegation_sids				security.T_SID_TABLE;
	v_sheet_table					security.T_SID_TABLE;

	v_region_sids_table				security.T_SID_TABLE;
BEGIN		
	v_sheet_table := security_pkg.SidArrayToTable(in_sheet_ids);

	SELECT DISTINCT delegation_sid
	  BULK COLLECT INTO v_delegation_sids
	  FROM sheet
	 WHERE sheet_id IN (SELECT column_value FROM TABLE(v_sheet_table));

	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_table
	  FROM region_list;

	OPEN out_region_cur FOR
		-- gets a bunch of regions and all their children (as a single tree)
		-- merging any common parts of the tree
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT parent_sid, active, region_sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type,
                       MAX(lvl) OVER (PARTITION BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type) lvl,
					   FIRST_VALUE(rn) OVER (PARTITION BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type
                         					     ORDER BY lvl DESC) rn
              	  FROM (SELECT parent_sid, active, NVL(link_to_region_sid,region_sid) region_sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type,
                        	   LEVEL lvl, ROWNUM rn
			       		  FROM v$region 
			      		 START WITH region_sid IN (
			      		 		SELECT rl.column_value 
			      		 		  FROM TABLE(v_region_sids_table) rl, region r, delegation_region dr, TABLE(v_delegation_sids) d
			      		 		 WHERE r.app_sid = v_app_sid AND dr.app_sid = v_app_sid AND r.app_sid = dr.app_sid AND
			      		 		       rl.column_value = r.region_sid AND r.region_sid = dr.region_sid AND
		   							   dr.delegation_sid = d.column_value)
			    	   CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
                	   ) x
			   )
	  GROUP BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type, lvl, rn
      ORDER BY rn;
      
	OPEN out_region_tag_cur FOR
		SELECT region_sid, tag_id
		  FROM region_tag
		 WHERE region_sid IN (
		 		SELECT NVL(link_to_region_sid, region_sid)
		 		  FROM region
					   START WITH region_sid IN (
							SELECT rl.column_value 
		  		 		  	  FROM TABLE(v_region_sids_table) rl, region r, delegation_region dr, TABLE(v_delegation_sids) d
		  		 		 	 WHERE r.app_sid = v_app_sid AND dr.app_sid = v_app_sid AND r.app_sid = dr.app_sid AND
								   rl.column_value = r.region_sid AND r.region_sid = dr.region_sid AND
								   dr.delegation_sid = d.column_value)
			    	   CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid);
END;


PROCEDURE GetRegionTree(
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_region_sids_table				security.T_SID_TABLE;
BEGIN
	-- XXX: act, what here?
	/*IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region tree for the dataview with sid '||in_dataview_sid);
	END IF;*/
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_table
	  FROM region_list;

	OPEN out_region_cur FOR
		-- gets a bunch of regions and all their children (as a single tree)
		-- merging any common parts of the tree
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT parent_sid, active, region_sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type,
                       MAX(lvl) OVER (PARTITION BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type) lvl,
					   FIRST_VALUE(rn) OVER (PARTITION BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type
                         					     ORDER BY lvl DESC) rn
              	  FROM (SELECT parent_sid, active, NVL(link_to_region_sid,region_sid) region_sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type,
                        	   LEVEL lvl, ROWNUM rn
			       		  FROM v$region 
			      		 START WITH region_sid IN (SELECT column_value FROM TABLE(v_region_sids_table))
			    	   CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid
                	   ) x
			   )
	  GROUP BY parent_sid, active, region_Sid, description, pos, geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref, region_type, lvl, rn
      ORDER BY rn;
      
	OPEN out_region_tag_cur FOR
		SELECT region_sid, tag_id
		  FROM region_tag
		 WHERE region_sid IN (
				SELECT NVL(link_to_region_sid,region_sid) region_sid
				  FROM region 
					   START WITH region_sid IN (SELECT column_value FROM TABLE(v_region_sids_table))
					   CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid);
END;	

PROCEDURE GetRegions(
	out_cur							OUT SYS_REFCURSOR,
	out_tag_cur						OUT SYS_REFCURSOR
)
AS
	v_region_sids_table				security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_table
	  FROM region_list;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ r.parent_sid, r.active, r.region_sid, r.description, r.pos, r.geo_latitude, r.geo_longitude, 
			   r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.disposal_dtm, 
			   r.acquisition_dtm, r.lookup_key, r.region_type, r.region_ref
		  FROM v$region r
		 WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_region_sids_table)); -- region_list is non-unique sometimes, e.g. Credit360.Reports duplicates regions if including children
		 
	OPEN out_tag_cur FOR
		SELECT region_sid, tag_id
		  FROM region_tag
		 WHERE region_sid IN (SELECT column_value FROM TABLE(v_region_sids_table)); -- region_list is non-unique sometimes
END;

PROCEDURE InitDataSource
AS
BEGIN
	-- add all dependencies of the calculations that we are performing (i.e. all normal calcs)
	INSERT INTO ind_list (ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT cd.ind_sid
		  FROM v$calc_dependency cd
	     	   START WITH cd.calc_ind_sid IN (SELECT ind_sid FROM ind_list) AND cd.calc_ind_type IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_REPORT_CALC)
	           CONNECT BY PRIOR cd.app_sid = cd.app_sid AND PRIOR cd.ind_sid = cd.calc_ind_sid AND PRIOR cd.ind_type != csr_data_pkg.IND_TYPE_STORED_CALC
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE InitAggregateDataSource
AS
BEGIN
	-- add all dependencies of the calculations that we are performing
	INSERT INTO ind_list (ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT cd.ind_sid
		  FROM v$calc_dependency cd
	     	   START WITH cd.calc_ind_sid IN (SELECT ind_sid FROM ind_list)
	           CONNECT BY PRIOR cd.app_sid = cd.app_sid AND PRIOR cd.ind_sid = cd.calc_ind_sid
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE GetAllIndDetails(
	out_cur							OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	OPEN out_cur FOR
		SELECT i.ind_sid, i.description,
	   		   NVL(i.scale, m.scale) scale,
	   		   NVL(i.format_mask, m.format_mask) format_mask, 
	   		   NVL(i.divisibility, m.divisibility) divisibility, i.aggregate, 
	   		   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, 
	   		   i.calc_description, i.calc_xml, i.ind_type, i.calc_start_dtm_adjustment,
			   i.calc_end_dtm_adjustment, m.description measure_description, i.measure_sid,
			   i.info_xml, i.start_month, i.gri, 
			   i.parent_sid, pos, i.target_direction, i.active,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance, 
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.normalize,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key, i.calc_output_round_dp
		  FROM v$ind i, measure m
		 WHERE i.ind_sid IN (SELECT column_value FROM TABLE(v_ind_list))
	       AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+);

	OPEN out_tag_cur FOR
		SELECT ind_sid, tag_id
		  FROM ind_tag
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_ind_list));
END;

PROCEDURE AddReportCalcInds
AS
	v_lvl							BINARY_INTEGER := 2;
BEGIN
	-- now we have figured out which stored calcs and calcs to recompute then get all the dependencies of those too
	-- we do this one tree level at a time to avoid explosions in the dependency tree due to adding the same
	-- subtree more than once -- Oracle appears to be incapable of pruning subtrees during connect by
	DELETE FROM temp_calc_tree;
	INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
		SELECT 1, null, ind_sid
		  FROM ind_list;
	LOOP
		INSERT INTO temp_calc_tree (lvl, parent_sid, ind_sid)
			SELECT v_lvl, cd.calc_ind_sid, cd.ind_sid
			  FROM csr.v$calc_dependency cd
			 WHERE cd.calc_ind_sid IN (SELECT ind_sid FROM temp_calc_tree WHERE lvl = v_lvl - 1)
			   AND cd.ind_sid NOT IN (SELECT ind_sid FROM temp_calc_tree);
		EXIT WHEN SQL%ROWCOUNT = 0;
		v_lvl := v_lvl + 1;
	END LOOP;
	
	INSERT INTO ind_list (ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT ind_sid
		  FROM temp_calc_tree
		 MINUS
		SELECT ind_sid
		  FROM ind_list;
END;

PROCEDURE GetIndAndReportCalcDetails(
	out_cur							OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_rep_calc_agg_child_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	-- to the requested set of data, add any indicators that reporting calcs rely on
	AddReportCalcInds;
	
	-- get ind details as normal
	GetAllIndDetails(out_cur, out_tag_cur);

	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	-- get reporting calc aggregate children
	OPEN out_rep_calc_agg_child_cur FOR
		-- now make a list of parent and child nodes that we'll need for aggregate functions
		SELECT DISTINCT i.parent_sid, i.ind_sid 
		  FROM calc_dependency cd
		  JOIN ind i ON i.parent_sid = cd.ind_sid
		  JOIN TABLE(v_ind_list) il ON il.column_value = cd.calc_ind_sid
		 WHERE cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
		   AND i.map_to_ind_sid IS NULL
		   AND i.measure_sid IS NOT NULL
		   AND i.ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC
		 ORDER BY parent_sid;
END;

-- return full info on all gas factors
PROCEDURE GetAllGasFactors(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	OPEN out_cur FOR
		SELECT f.factor_type_id, f.gas_type_id,
			   f.region_sid, f.geo_country, f.geo_region, f.egrid_ref,
			   f.start_dtm, f.end_dtm, f.std_measure_conversion_id, 
			   POWER((f.value - smc.c) / smc.a, 1 / smc.b) value,
		       0 is_virtual			   
		  FROM factor_type ft, factor f, std_measure_conversion smc
		 WHERE ft.factor_type_id IN (SELECT i.factor_type_id
		 							   FROM ind i
									   JOIN TABLE(v_ind_list) il ON il.column_value = i.ind_sid
		 							)
		   AND ft.factor_type_id = f.factor_type_id
		   AND f.is_selected = 1
		   AND f.std_measure_conversion_id = smc.std_measure_conversion_id
		 ORDER BY f.start_dtm;
END;

PROCEDURE GetIndDependencies(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	OPEN out_cur FOR
		SELECT cd.calc_ind_sid, cd.ind_sid
		  FROM v$calc_dependency cd
		  JOIN TABLE(v_ind_list) il ON il.column_value = cd.calc_ind_sid
		 WHERE cd.calc_ind_type IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_REPORT_CALC); -- don't return dependencies for stored calcs
END;

PROCEDURE GetAggregateIndDependencies(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	OPEN out_cur FOR
		SELECT cd.calc_ind_sid, cd.ind_sid
		  FROM v$calc_dependency cd
		  JOIN TABLE(v_ind_list) il on il.column_value = cd.calc_ind_sid;
END;

PROCEDURE GetAggregateChildren(
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_ind_list						csr_data_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;

	OPEN out_cur FOR
		-- now make a list of parent and child nodes that we'll need for aggregate functions
		SELECT DISTINCT i.parent_sid, i.ind_sid 
          FROM calc_dependency cd
		  JOIN ind i ON i.parent_sid = cd.ind_sid
		  JOIN TABLE(v_ind_list) il ON il.column_value = cd.calc_ind_sid
         WHERE cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
           AND i.map_to_ind_sid IS NULL
           AND i.measure_sid IS NOT NULL
         ORDER BY parent_sid;
END;

PROCEDURE GetRegionPctOwnership(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- XXX: this isn't quite right -- we are reading all regions, but don't need them
	-- this is to work around the fact that we don't know which regions we are going to
	-- read here -- some more work needs to be done on the datasource as we
	-- read values for a region tree that includes the requested regions; these regions
	-- vary by data source type but aren't recorded anywhere so at this point we don't
	-- have a full list. (Reading all the data won't lead to incorrect results, just
	-- some wasted time).  This work needs doing anyway as reading the whole region tree
	-- for the standard ValDataSource is very wasteful -- the tree is only required
	-- if we have to re-run aggregation.
	OPEN out_cur FOR
		SELECT pct.region_sid, pct.start_dtm, pct.end_dtm, pct.pct
		  FROM pct_ownership pct
		 ORDER BY pct.region_sid, pct.start_dtm;
END;

PROCEDURE INTERNAL_FetchResult(
	out_val_cur				OUT	SYS_REFCURSOR,
	out_file_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid			security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_get_value_result	T_GET_VALUE_RESULT_TABLE;
BEGIN
	SELECT T_GET_VALUE_RESULT_ROW(
		period_start_dtm,
		period_end_dtm,
		source,
		source_id,
		source_type_id,
		ind_sid,
		region_sid,
		val_number,
		error_code,
		changed_dtm,
		dbms_lob.substr(note, 2000, 1),
		flags,
		is_leaf,
		is_merged,
		path
	)
	  BULK COLLECT INTO v_get_value_result
	  FROM get_value_result;

	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS*/ period_start_dtm, period_end_dtm, ind_sid, region_sid, 
			   val_number, error_code, changed_dtm, note, source, source_id, source_type_id, flags, 
			   is_merged
		  FROM TABLE(v_get_value_result)
      -- sorted for running through the value normaliser
      -- Note: The normalizer will skip overlapping periods. So if we have a delegation split by period and there is, say, yearly data at one level and monthly data
      -- lower down then we want data that is present at the monthly level to take precedence over no data present at the yearly level (hence the switch on val_number IS NULL).
      -- This will fail if the first period in the split delegation is skipped (in which case the yearly "no data" will once again cause all monthly figures to be discarded), but
      -- this is - I think - a fairly safe change, and it solves the specific case raised by FB5103. (Whereas always taking monthly data over yearly data may well be a breaking change,
      -- but I don't know enough about the aggregation engine to be sure either way.)
      ORDER BY ind_sid, region_sid, period_start_dtm, CASE WHEN val_number IS NULL THEN 1 ELSE 0 END, period_end_dtm DESC, changed_dtm DESC, is_merged DESC;

	-- Fetch files
	OPEN out_file_cur FOR
		SELECT /*+ALL_ROWS*/ r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM TABLE(v_get_value_result) r
		  JOIN val_file vf ON vf.app_sid = v_app_sid
		  JOIN file_upload fu ON fu.app_sid = v_app_sid
		 WHERE 1 = 0
		   AND vf.app_sid = fu.app_sid
		   AND vf.val_id = r.source_id 
		   AND r.source = 0
		   AND fu.file_upload_sid = vf.file_upload_sid;
END;

PROCEDURE GetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
BEGIN
/*TODO: security, on what? */
/*	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;*/
	DELETE FROM get_value_result;
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_merged)
		-- stuff from val we need incl for calculations
		SELECT /*+ALL_ROWS CARDINALITY(rl, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id, v.source_type_id, v.ind_sid, v.region_sid, 
			   v.val_number, v.error_code, v.changed_dtm, v.note, v.flags, 1 is_merged
		  FROM ind_list il, val v, region_list rl
		 WHERE v.app_sid = v_app_sid
		   AND il.ind_sid = v.ind_sid
		   AND rl.region_sid = v.region_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm;

	-- Fetch vals
	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;

PROCEDURE GetScenarioRunValues(
	in_scenario_run_sid		IN	scenario_run.scenario_run_sid%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	DELETE FROM get_value_result;
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_merged)
		-- stuff from val we need incl for calculations
		SELECT /*+ALL_ROWS CARDINALITY(rl, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, 0 source, 0 val_id, v.source_type_id, v.ind_sid, v.region_sid, 
			   v.val_number, v.error_code, SYSDATE changed_dtm, null note, null flags, 1 is_merged
		  FROM ind_list il, scenario_run_val v, region_list rl
		 WHERE v.scenario_run_sid = in_scenario_run_sid
		   AND v.app_sid = v_app_sid
		   AND il.ind_sid = v.ind_sid
		   AND rl.region_sid = v.region_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm;

	-- Fetch vals
	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;

PROCEDURE GetAllSheetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_unmerged_consistent			customer.unmerged_consistent%TYPE;
	v_sheet_i_r_tbl					T_SHEETS_IND_REG_TO_USE_TABLE;
BEGIN
/*TODO: security, on what? */
/*	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;
*/
	SELECT unmerged_consistent
	  INTO v_unmerged_consistent
	  FROM customer
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM get_value_result;

	-- broken out to make the query simpler so that poor old Oracle can finish running it before Christmas	
	DELETE FROM region_list_2;
	INSERT INTO region_list_2 (app_sid, region_sid, is_leaf)
		SELECT app_sid, region_sid, is_leaf 
		  FROM (SELECT app_sid, region_sid, row_number() over (partition by region_sid order by lvl desc) rn, is_leaf
				  FROM (SELECT app_sid, NVL(link_to_region_Sid, region_sid) region_sid, level lvl, CONNECT_BY_ISLEAF is_leaf
				  FROM region
					   START WITH app_sid = v_app_sid AND region_sid IN (SELECT region_sid FROM region_list)
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid))
		  WHERE rn = 1;
		  
		  
	-- The old method of fetching unmerged values is a bit inconsistent as it ignores null values, which can
	-- lead to the unintended mixing of data from different sheets.  This behaviour has been left to avoid 
	-- numbers changing for existing customers, and a method that treats nulls the same as numbers has been
	-- added.  It's still somewhat inconsistent.
	IF v_unmerged_consistent = 0 THEN
		-- more breaking out
		DELETE FROM temp_sheets_to_use;
		INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
			SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour
			  FROM (SELECT app_sid, delegation_sid, level lvl
					  FROM delegation 
						   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP')
						   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
				   sheet_with_last_action sla
			 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
			   AND sla.is_visible = 1
			   AND sla.end_dtm > in_start_dtm
			   AND sla.start_dtm < in_end_dtm;

		-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
		-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're 
		-- processing a lot of data, and don't care too much about note fidelity.
		INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
			SELECT /*+ALL_ROWS*/
				   start_dtm period_start_dtm, end_dtm period_end_dtm, 1 source, sheet_value_id, 0 source_type_id, ind_sid, region_sid,
				   val_number, null error_code, set_dtm changed_dtm, dbms_lob.substr(note, 2000, 1) note, NULL, is_leaf, 0 is_merged
			  FROM (SELECT /*+CARDINALITY(rp, 10000) CARDINALITY(il, 1) CARDINALITY(sv, 1000000) CARDINALITY(ts, 10000) CARDINALITY(di, 500000) CARDINALITY(dr, 10000)*/
			  			   sv.sheet_value_id, ts.start_dtm, ts.end_dtm, di.ind_sid, dr.region_sid, sv.val_number, sv.set_dtm, sv.note, rp.is_leaf,
			          	   ROW_NUMBER() OVER (
							PARTITION BY di.ind_sid,dr.region_sid,ts.start_dtm,ts.end_dtm 
							ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
				 	  FROM delegation_ind di, delegation_region dr, sheet_value sv, temp_sheets_to_use ts,
					  	   region_list_2 rp, ind_list il
					 WHERE di.ind_sid = il.ind_sid
				       AND dr.region_sid = rp.region_sid
				   	   AND di.app_sid = ts.app_sid AND di.delegation_sid = ts.delegation_sid
				   	   AND dr.app_sid = ts.app_sid AND dr.delegation_sid = ts.delegation_sid
					   AND sv.app_sid = ts.app_sid AND sv.sheet_id = ts.sheet_id
					   AND sv.app_sid = di.app_sid AND sv.ind_sid = di.ind_sid
					   AND sv.ind_sid = il.ind_sid
					   AND sv.app_sid = dr.app_sid AND sv.region_sid = dr.region_sid)
			 WHERE SEQ = 1;
	
		-- since is_merged=0 above, is_merged=1 below
		INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
			SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.source_type_id, v.ind_sid, v.region_sid, 
	          	   v.val_number, v.error_code, v.changed_dtm, dbms_lob.substr(v.note, 2000, 1) note, NULL, is_leaf, 1 is_merged
			  FROM val v, region_list_2 r, ind_list il, ind i -- hack: include propagate down values
	     	 WHERE v.app_sid = v_app_sid
		       AND r.app_sid = v_app_sid
		       AND i.app_sid = v_app_sid
		       AND v.app_sid = r.app_sid
		       AND v.app_sid = i.app_sid
		       AND r.app_sid = i.app_sid
		       AND v.ind_sid = il.ind_sid
		       AND v.period_end_dtm > in_start_dtm
		       AND v.period_start_dtm < in_end_dtm
		       -- hack: include propagate down values
		       AND v.ind_sid = i.ind_sid
		       AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR i.aggregate in ('DOWN', 'FORCE DOWN'))
		       -- hack ends
		       AND v.region_sid = r.region_sid;
	ELSE
		-- more breaking out
		DELETE FROM temp_sheets_to_use;
		INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
			SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour
			  FROM (SELECT app_sid, delegation_sid, level lvl
					  FROM delegation 
						   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP')
						   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
				   sheet_with_last_action sla
			 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
			   AND sla.is_visible = 1
			   AND sla.end_dtm > in_start_dtm
			   AND sla.start_dtm < in_end_dtm;
		
		SELECT /*+ALL_ROWS CARDINALITY(ts, 10000) CARDINALITY(il, 10000) CARDINALITY(rl, 10000)*/
			T_SHEETS_IND_REG_TO_USE_ROW(ts.app_sid, ts.delegation_sid, ts.lvl, ts.sheet_id, di.ind_sid, dr.region_sid, ts.start_dtm, ts.end_dtm, ts.last_action_colour)
		BULK COLLECT INTO v_sheet_i_r_tbl
		  FROM temp_sheets_to_use ts
		  JOIN delegation_ind di ON ts.app_sid = di.app_sid AND ts.delegation_sid = di.delegation_sid
		  JOIN delegation_region dr ON ts.app_sid = dr.app_sid AND ts.delegation_sid = dr.delegation_sid;

		-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
		-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're 
		-- processing a lot of data, and don't care too much about note fidelity.
		INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
			SELECT /*+ALL_ROWS CARDINALITY(rp, 10000) CARDINALITY(il, 1)*/ start_dtm period_start_dtm, end_dtm period_end_dtm, 1 source, sheet_value_id, 0 source_type_id, ind_sid, region_sid,
				   val_number, null error_code, set_dtm changed_dtm, dbms_lob.substr(note, 2000, 1) note, NULL, is_leaf, 0 is_merged
			  FROM (SELECT sv.sheet_value_id, ts.start_dtm, ts.end_dtm, ts.ind_sid, ts.region_sid, sv.val_number, sv.set_dtm, sv.note, rp.is_leaf,
			          	   ROW_NUMBER() OVER (
							PARTITION BY ts.ind_sid, ts.region_sid, ts.start_dtm, ts.end_dtm 
							ORDER BY DECODE(ts.last_action_colour,'G',1,'O',2,'R',3), ts.lvl DESC, ts.sheet_id DESC, sv.sheet_value_id) SEQ
					  FROM TABLE(v_sheet_i_r_tbl) ts
					  JOIN region_list_2 rp ON rp.app_sid = ts.app_sid AND rp.region_sid = ts.region_sid
					  JOIN ind_list il ON ts.ind_sid = il.ind_sid
					  LEFT JOIN sheet_value sv ON ts.app_sid = sv.app_sid AND ts.sheet_id = sv.sheet_id 
					   AND ts.app_sid = sv.app_sid AND ts.ind_sid = sv.ind_sid 
					   AND ts.app_sid = sv.app_sid AND ts.region_sid = sv.region_sid)
			 WHERE SEQ = 1;
	
		-- since is_merged=0 above, is_merged=1 below
		INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
			SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.source_type_id, v.ind_sid, v.region_sid, 
	          	   v.val_number, v.error_code, v.changed_dtm, dbms_lob.substr(v.note, 2000, 1) note, NULL, is_leaf, 1 is_merged
			  FROM val v, region_list_2 r, ind_list il, ind i
	     	 WHERE v.app_sid = v_app_sid
		       AND r.app_sid = v_app_sid
		       AND i.app_sid = v_app_sid
		       AND v.app_sid = r.app_sid
		       AND v.app_sid = i.app_sid
		       AND r.app_sid = i.app_sid
		       AND v.ind_sid = il.ind_sid
		       AND v.period_end_dtm > in_start_dtm
		       AND v.period_start_dtm < in_end_dtm
		       -- hack: include propagate down values
		       AND v.ind_sid = i.ind_sid
		       AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR i.aggregate in ('DOWN', 'FORCE DOWN'))
		       -- hack ends
		       AND v.region_sid = r.region_sid
		       -- check value isn't on one of the sheets we've selected
		       AND NOT EXISTS (SELECT 1
		       					 FROM TABLE(v_sheet_i_r_tbl) ts
		       					WHERE v.app_sid = ts.app_sid
					  			  AND v.period_end_dtm > ts.start_dtm
					  			  AND v.period_start_dtm < ts.end_dtm
					  			  AND v.app_sid = ts.app_sid AND v.ind_sid = ts.ind_sid
					  			  AND v.app_sid = ts.app_sid AND v.region_sid = ts.region_sid);
	END IF;
    
	-- Fetch vals
	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;

PROCEDURE GetUserSheetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_user_sid		security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	DELETE FROM get_value_result;

	-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
	-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're 
	-- processing a lot of data, and don't care too much about note fidelity.
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
		SELECT /*+ALL_ROWS CARDINALITY(region_list, 10000) CARDINALITY(il, 1)*/ x.period_start_dtm, x.period_end_dtm, x.source, x.source_id, x.source_type_id, x.ind_sid, x.region_sid, 
			   x.val_number, x.error_code, x.changed_dtm, x.note, NULL, y.is_leaf, x.is_merged
		  FROM (
			SELECT start_dtm period_start_dtm, end_dtm period_end_dtm, 1 source, sheet_value_id source_id, 0 source_type_id, ind_sid, region_sid,
				   val_number, null error_code, set_dtm changed_dtm, dbms_lob.substr(note, 2000, 1) note, 0 is_merged 
			  FROM (
			   SELECT sla.sheet_id, sv.sheet_value_id, sla.start_dtm, sla.end_dtm, di.ind_sid, dr.region_sid, sv.val_number, sv.set_dtm, sv.note, sla.last_action_colour,
			          ROW_NUMBER() OVER (PARTITION BY di.ind_sid,dr.region_sid,sla.start_dtm,sla.end_dtm ORDER BY dl.is_mine * 4 + DECODE(sla.last_action_colour,'G',3,'O',2,'R',1) DESC) SEQ
				 FROM delegation_ind di, delegation_region dr, delegation d,
				  	  sheet_with_last_action sla, sheet_value sv,
				  	   (SELECT du.app_sid, du.delegation_sid, 1 is_mine
						  FROM delegation_user du
						 WHERE du.app_sid = v_app_sid 
						   AND du.user_sid = v_user_sid
						   AND du.inherited_from_sid = du.delegation_sid
						 UNION
						SELECT dd.app_sid, dd.delegation_sid, 0 is_mine
						  FROM delegation_delegator dd
						 WHERE dd.app_sid = v_app_sid
						   AND dd.delegator_sid = v_user_sid) dl,
					   ind_list il
				 WHERE di.app_sid = v_app_sid
				   AND d.app_sid = v_app_sid
				   AND sla.app_sid = v_app_sid
				   AND sv.app_sid = v_app_sid
				   AND dl.app_sid = v_app_sid
				   AND di.app_sid = dr.app_sid
				   AND di.app_sid = d.app_sid
				   AND di.app_sid = sla.app_sid
				   AND di.app_sid = sv.app_sid
				   AND di.app_sid = dl.app_sid
				   AND dr.app_sid = d.app_sid
				   AND dr.app_sid = sla.app_sid
				   AND dr.app_sid = sv.app_sid
				   AND dr.app_sid = dl.app_sid
				   AND d.app_sid = sla.app_sid
				   AND d.app_sid = sv.app_sid
				   AND d.app_sid = dl.app_sid
				   AND sla.app_sid = d.app_sid
				   AND sla.app_sid = dl.app_sid
				   AND d.app_sid = dl.app_sid
				   AND di.ind_sid = il.ind_sid
				   AND dr.region_sid IN (
					     SELECT NVL(link_to_region_sid,region_sid)
			           	   FROM region
			 			  START WITH region_sid IN (
		 			  	SELECT region_sid FROM region_list
			 			  	)
						CONNECT BY PRIOR NVL(link_to_region_sid,region_sid) = parent_sid
				   	)
				   AND di.delegation_sid = d.delegation_sid
				   AND dr.delegation_sid = d.delegation_sid
				   AND d.delegation_sid = dl.delegation_sid
				   AND sla.delegation_sid = d.delegation_sid
				   AND sv.sheet_id = sla.sheet_id
				   AND sv.ind_sid = di.ind_sid
			   	   AND sv.ind_sid = il.ind_sid				   
				   AND sv.region_sid = dr.region_sid
				   AND sla.end_dtm > in_start_dtm
				   AND sla.start_dtm < in_end_dtm
				   AND sla.is_visible = 1
				   -- removed at Tuli's request 28/2
			  	   --AND (last_action_colour !='R' OR dl.is_mine = 1) -- red is ok, so long as it's mine
				)
			 WHERE SEQ = 1
		UNION ALL -- since is_merged=0 above, is_merged=1 below
			SELECT /*+ALL_ROWS*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.source_type_id, v.ind_sid, v.region_sid, 
				   v.val_number, v.error_code, v.changed_dtm, dbms_lob.substr(v.note, 2000, 1) note, 1 is_merged
			  FROM val v, ind_list il, ind i
	     	 WHERE v.app_sid = v_app_sid
		   	   AND v.ind_sid = il.ind_sid
	       	   AND v.period_end_dtm > in_start_dtm
	       	   AND v.period_start_dtm < in_end_dtm
			   -- hack: include propagate down values
			   AND v.ind_sid = i.ind_sid
			   AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR i.aggregate in ('DOWN', 'FORCE DOWN'))
			   -- hack ends
	       	   AND v.region_sid IN (
			  		SELECT NVL(link_to_region_sid,region_sid)
			          FROM region
			 			   START WITH app_sid = v_app_sid AND region_sid IN (SELECT region_sid FROM region_list)
					       CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid)
		) x, (
		  SELECT NVL(link_to_region_sid,region_sid) region_sid, CONNECT_BY_ISLEAF is_leaf
		    FROM region
				 START WITH app_sid = v_app_sid AND region_sid IN (SELECT region_sid FROM region_list)
		         CONNECT BY app_sid = v_app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid
		) y
		WHERE x.region_sid = y.region_sid;

	-- Fetch vals
	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;

PROCEDURE GetStoredRecalcValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_ind_list				csr_data_pkg.T_NUMBER_ARRAY;
	v_region_list			csr_data_pkg.T_NUMBER_ARRAY;
	v_get_value_result		T_GET_VALUE_RESULT_TABLE;
BEGIN	
	SELECT il.ind_sid
	  BULK COLLECT INTO v_ind_list
	  FROM ind_list il;
	
	SELECT rl.region_sid
	  BULK COLLECT INTO v_region_list
	  FROM region_list rl;
	
	SELECT T_GET_VALUE_RESULT_ROW(
		period_start_dtm,
		period_end_dtm,
		source,
		source_id,
		source_type_id,
		ind_sid,
		region_sid,
		val_number,
		error_code,
		changed_dtm,
		note,
		flags,
		is_leaf,
		is_merged,
		path
	)
	  BULK COLLECT INTO v_get_value_result
	  FROM get_value_result;

	OPEN out_val_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, v.ind_sid, v.region_sid, 
			   v.val_number, v.error_code, v.changed_dtm, null note, CAST(0 AS NUMBER(10)) source, v.val_id source_id, v.source_type_id, null flags, 
			   CAST(1 AS NUMBER(10)) is_merged
		  FROM TABLE(v_ind_list) il
		  JOIN val_converted v ON v.app_sid = v_app_sid
		  JOIN TABLE(v_region_list) r ON r.column_value = v.region_sid
		 WHERE il.column_value = v.ind_sid
		   AND v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
	     ORDER BY ind_sid, region_sid, period_start_dtm, CASE WHEN val_number IS NULL THEN 1 ELSE 0 END, period_end_dtm DESC, changed_dtm DESC;

	-- Dummy files cur
	OPEN out_file_cur FOR
		SELECT /*+ALL_ROWS*/ r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM TABLE(v_get_value_result) r, val_file vf, file_upload fu
		 WHERE 1 = 0;
END;

PROCEDURE GetSheetValues(	
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR,
    out_file_cur					OUT SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_sheet_start_dtm				sheet.start_dtm%TYPE;
	v_sheet_end_dtm					sheet.end_dtm%TYPE;
	v_sheet_table					security.T_SID_TABLE;
BEGIN	
	v_app_sid := security_pkg.GetApp();

	v_sheet_table := security_pkg.SidArrayToTable(in_sheet_ids);

	DELETE FROM temp_sheet_id;
	INSERT INTO temp_sheet_id
		SELECT column_value
		  FROM TABLE(v_sheet_table);

	DELETE FROM temp_delegation_sid;
	INSERT INTO temp_delegation_sid (delegation_sid)
		SELECT DISTINCT delegation_sid
		  FROM sheet
		 WHERE sheet_id IN (SELECT sheet_id FROM temp_sheet_id);

	SELECT MIN(start_dtm), MAX(end_dtm)
	  INTO v_sheet_start_dtm, v_sheet_end_dtm
	  FROM sheet
	 WHERE sheet_id IN (SELECT sheet_id FROM temp_sheet_id);
		  
	-- broken out to make the query simpler so that poor old Oracle can finish running it before Christmas	
	DELETE FROM region_list_2;
	INSERT INTO region_list_2 (app_sid, region_sid, is_leaf)
		SELECT app_sid, region_sid, is_leaf 
		  FROM (SELECT app_sid, region_sid, row_number() over (partition by region_sid order by lvl desc) rn, is_leaf
				  FROM (SELECT app_sid, NVL(link_to_region_Sid, region_sid) region_sid, level lvl, CONNECT_BY_ISLEAF is_leaf
				  FROM region
					   START WITH app_sid = v_app_sid AND region_sid IN (SELECT region_sid FROM region_list)
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid))
		  WHERE rn = 1;

	DELETE FROM get_value_result;
	-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
	-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're 
	-- processing a lot of data, and don't care too much about note fidelity.
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
		SELECT s.start_dtm period_start_dtm, s.end_dtm period_end_dtm, 1 source, sv.sheet_value_id, 0 source_type_id, di.ind_sid, dr.region_sid,
			   sv.val_number, null error_code, sv.set_dtm changed_dtm, dbms_lob.substr(sv.note, 2000, 1) note, NULL, is_leaf, 0 is_merged
 		  FROM delegation_ind di, delegation_region dr, delegation d,
			   sheet s, sheet_value sv, region_list_2 rp, ind_list il,
			   temp_sheet_id ts
	     WHERE di.app_sid = v_app_sid AND di.app_sid = dr.app_sid AND di.app_sid = d.app_sid AND di.app_sid = s.app_sid AND di.app_sid = sv.app_sid AND di.app_sid = rp.app_sid
		   AND dr.app_sid = v_app_sid AND dr.app_sid = d.app_sid AND dr.app_sid = s.app_sid AND dr.app_sid = sv.app_sid AND dr.app_sid = rp.app_sid
		   AND d.app_sid = v_app_sid AND d.app_sid = s.app_sid AND d.app_sid = sv.app_sid AND d.app_sid = rp.app_sid
		   AND s.app_sid = v_app_sid AND s.app_sid = sv.app_sid AND s.app_sid = rp.app_sid
		   AND sv.app_sid = v_app_sid AND sv.app_sid = rp.app_sid
		   AND di.ind_sid = il.ind_sid
		   AND dr.region_sid = rp.region_sid
		   AND di.delegation_sid = d.delegation_sid
		   AND dr.delegation_sid = d.delegation_sid
		   AND s.sheet_id = ts.sheet_id
		   AND s.delegation_sid = d.delegation_sid
		   AND sv.sheet_id = s.sheet_id
		   AND sv.ind_sid = di.ind_sid
		   AND sv.ind_sid = il.ind_sid
		   AND sv.region_sid = dr.region_sid;

	DELETE FROM temp_vds_ind;
	INSERT INTO temp_vds_ind (ind_sid, aggregate)
		SELECT ind_sid, aggregate
		  FROM ind
		 WHERE ind_sid IN (SELECT ind_sid FROM ind_list);
		 
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)		
		SELECT /*+ALL_ROWS CARDINALITY(r, 10000) CARDINALITY(il, 1)*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.source_type_id, v.ind_sid, v.region_sid, 
          		v.val_number, v.error_code, v.changed_dtm, dbms_lob.substr(v.note, 2000, 1) note, NULL, is_leaf, 1 is_merged
		  FROM val v, region_list_2 r, temp_vds_ind il
	     WHERE v.app_sid = v_app_sid AND v.ind_sid = il.ind_sid 
	       AND v.period_end_dtm > in_start_dtm
	       AND v.period_start_dtm < in_end_dtm
	       -- hack: include propagate down values
	       AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR il.aggregate in ('DOWN', 'FORCE DOWN'))
	       -- hack ends
	       AND v.app_sid = r.app_sid AND v.region_sid = r.region_sid
	       -- check value isn't on the sheet
	       AND NOT (
	       			(v.app_sid, v.ind_sid) IN (SELECT /*+CARDINALITY(tds, 100)*/ app_sid, ind_sid
				       					   		 FROM delegation_ind di, temp_delegation_sid tds
				       					  	    WHERE di.delegation_sid = tds.delegation_sid)
				AND (v.region_sid) IN (SELECT region_sid
										 FROM region_list_2)
				AND v.period_end_dtm > v_sheet_start_dtm 
				AND v.period_start_dtm < v_sheet_end_dtm);

	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;

PROCEDURE GetPendingValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid			security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
BEGIN
/*TODO: security, on what? */
/*	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dataview_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the dataview with sid '||in_dataview_sid);
	END IF;
*/
	-- broken out to make the query simpler so that poor old Oracle can finish running it before Christmas	
	DELETE FROM region_list_2;
	INSERT INTO region_list_2 (app_sid, region_sid, is_leaf)
		SELECT app_sid, region_sid, is_leaf 
		  FROM (SELECT app_sid, region_sid, row_number() over (partition by region_sid order by lvl desc) rn, is_leaf
				  FROM (SELECT app_sid, NVL(link_to_region_Sid, region_sid) region_sid, level lvl, CONNECT_BY_ISLEAF is_leaf
				  FROM region
					   START WITH app_sid = v_app_sid AND region_sid IN (SELECT region_sid FROM region_list)
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid,region_sid) = parent_sid))
		  WHERE rn = 1;

	DELETE FROM get_value_result;
	-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
	-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're 
	-- processing a lot of data, and don't care too much about note fidelity.
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, source_type_id, ind_sid, region_sid, val_number, error_code, changed_dtm, note, flags, is_leaf, is_merged)
        SELECT /*+ALL_ROWS CARDINALITY(rp, 10000) CARDINALITY(il, 1)*/ pp.start_dtm period_start_dtm, pp.end_dtm period_end_dtm, 1 source, pv.pending_val_id, 0 source_type_id, pi.maps_to_ind_sid ind_sid, pr.maps_to_region_sid region_sid,
               pv.val_number, null error_code, SYSDATE changed_dtm, dbms_lob.substr(note, 2000, 1) note, NULL, is_leaf, 0 is_merged
          FROM customer c, reporting_period rp, pending_dataset pds, 
               pending_ind pi, pending_region pr, pending_period pp, pending_val pv, 
               ind_list il, region_list_2 rp
         WHERE c.app_sid = security_pkg.getApp
           AND c.current_reporting_period_sid = rp.reporting_period_sid
           AND rp.reporting_period_sid = pds.reporting_period_sid
           AND pds.pending_dataset_id = pi.pending_dataset_id
           AND pi.maps_to_ind_sid = il.ind_sid -- restrict to the indicators we're asking for
           AND pi.pending_ind_id = pv.pending_ind_id
           AND pds.pending_dataset_id = pr.pending_dataset_id
           AND pr.maps_to_region_sid = rp.region_sid -- restrict to the regions we're asking for
           AND pr.pending_region_id = pv.pending_region_id
           AND pds.pending_dataset_id = pp.pending_dataset_id
           AND pp.end_dtm > in_start_dtm  -- restrict to the period we're asking for
           AND pp.start_dtm < in_end_dtm
           AND pp.pending_period_id = pv.pending_period_id
		UNION ALL -- since is_merged=0 above, is_merged=1 below
		SELECT /*+ALL_ROWS*/ v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.source_type_id, v.ind_sid, v.region_sid, 
          	   v.val_number, v.error_code, v.changed_dtm, dbms_lob.substr(v.note, 2000, 1) note, NULL, is_leaf, 1 is_merged
		  FROM val v, region_list_2 r, ind_list il, ind i -- hack: include propagate down values
	     WHERE v.app_sid = v_app_sid
	       AND r.app_sid = v_app_sid
	       AND i.app_sid = v_app_sid
	       AND v.app_sid = r.app_sid
	       AND v.app_sid = i.app_sid
	       AND r.app_sid = i.app_sid
	       AND v.ind_sid = il.ind_sid
	       AND v.period_end_dtm > in_start_dtm
	       AND v.period_start_dtm < in_end_dtm
	       -- hack: include propagate down values
	       AND v.ind_sid = i.ind_sid
	       AND (v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR OR i.aggregate in ('DOWN', 'FORCE DOWN'))
	       -- hack ends
	       AND v.region_sid = r.region_sid;
    
	-- Fetch vals
	INTERNAL_FetchResult(out_val_cur, out_file_cur);
END;


END;
/
