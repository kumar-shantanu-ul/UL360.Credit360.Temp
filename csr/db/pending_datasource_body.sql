CREATE OR REPLACE PACKAGE BODY CSR.pending_datasource_pkg AS

-- given an indicator, region and period this works out what
-- things depend on the indicator, and then returns an appropriate
-- set of cursors for doing the recalculations for all things
-- that use this indicator
PROCEDURE InitForValueChange(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_req_period_span_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_pending_dataset_Id	pending_dataset.pending_dataset_id%TYPE;
	v_dependent_ind_ids 	security_pkg.T_SID_IDS;
	v_region_ids 			security_pkg.T_SID_IDS;
	v_maps_to_ind_sid		security_pkg.T_SID_ID;
	v_start_dtm				pending_period.start_dtm%TYPE;
	v_end_dtm				pending_period.end_dtm%TYPE;
BEGIN
	-- figure out dates required
	SELECT start_dtm, end_dtm, pending_dataset_id
	  INTO v_start_dtm, v_end_dtm, v_pending_dataset_id
	  FROM pending_period
	 WHERE pending_period_id = in_pending_period_id;
	
	-- return this as a cursor + some other useful info
	OPEN out_req_period_span_cur FOR
		SELECT v_start_dtm start_dtm, v_end_dtm end_dtm, 
			   MONTHS_BETWEEN(v_end_Dtm, v_start_dtm) interval, v_pending_dataset_id pending_dataset_id
		  FROM DUAL;
	
	-- figure out what calculations our indicator uses
	SELECT maps_to_ind_sid
	  INTO v_maps_to_ind_sid
	  FROM pending_ind
	 WHERE pending_ind_id = in_pending_ind_id;

	-- it can only be used in calculations if it's mapped
	IF v_maps_to_ind_sid IS NOT NULL THEN
		SELECT pending_ind_id
		  BULK COLLECT INTO v_dependent_ind_ids
		  FROM (
		    SELECT pending_ind_id 
		      FROM TABLE(calc_pkg.GetAllCalcsUsingIndAsTable(v_maps_to_ind_sid))i, pending_ind pi
			 WHERE pi.pending_dataset_Id = v_pending_dataset_id
			   AND pi.maps_to_ind_sid = i.dep_ind_sid
			 UNION 
			SELECT in_pending_ind_id
			  FROM DUAL
		 );
	ELSE	
		-- it won't have any calc depending on it because it's not mapped
		v_dependent_ind_ids(1) := in_pending_ind_id;
	END IF;
	
	-- just one region
	v_region_ids(1) := in_pending_region_id;
		
	
	InitDataSource(
		in_act_id, 
		v_pending_dataset_id, 
		v_dependent_ind_ids, 
		v_region_ids,
		v_start_dtm, 
		v_end_dtm,
		MONTHS_BETWEEN(v_end_dtm, v_start_dtm), -- a period is one interval
		in_include_stored_calcs,	
		out_inds_cur,
		out_regions_cur,
		out_aggr_children_cur,
		out_ind_depends_cur,
		out_values_cur,
		out_dates_cur,
		out_pending_inds_cur,
		out_pending_val_cur,
		out_variance_cur
	);
END;


/*               +----- out_inds_cur--------+
 *               |                          |
 *             +-v--------------------------v--+
 *   +=========+==============+==============+ |
 *   # PENDING # INDS MAPPED  # DEPENDENCIES # |
 *   #  INDS   # TO FROM      #             <-------- out_ind_depends_cur
 *   #   ^     # PENDING INDS #              # |
 *   +===|=====+==============+==============+ | <--- out_values_cur
 *       |     |              # AGGREGATE    # |
 *       |     |              # CALC        <-------- out_aggr_children_cur
 *  out_pending|              # CHILDREN     # |
 *  _inds_cur  |              +==============+ |
 * (+ val_cur) +-------------------------------+
 */
PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_pending_ind_ids		IN	security_pkg.T_SID_IDS,
	in_pending_region_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm			IN	pending_period.start_dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_interval_months		IN	NUMBER, -- number of months in the interval (3 = quarterly)
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_ind_list				T_SID_AND_DESCRIPTION_TABLE;
	v_ind_tbl				security.T_SID_TABLE;
	v_region_tbl			security.T_SID_TABLE;
	v_pp_start_dtm			pending_period.start_dtm%TYPE;
	v_pp_end_dtm			pending_period.end_dtm%TYPE;
	v_unmapped_region_cnt 	NUMBER;
	v_region_nodes			security.T_SID_TABLE;
	v_min_tolerance_months	NUMBER;
	v_start_dtm_adjustment  NUMBER;
	v_actual_start_dtm		DATE;
	v_actual_end_dtm		DATE;
BEGIN	
    -- crap hack for ODP.NET
    IF in_pending_ind_ids IS NULL OR (in_pending_ind_ids.COUNT = 1 AND in_pending_ind_ids(1) IS NULL) THEN
        RETURN;
    END IF;	 
    
    v_ind_tbl := security_pkg.SidArrayToTable(in_pending_ind_ids);
    v_region_tbl := security_pkg.SidArrayToTable(in_pending_region_ids);
    
    -- TODO: check all pending inds have same pending_dataset_Id as that passed in?
    
	-- the datasource thing likes actual IND_SIDS, so fish these out and init the generic 
	-- datasource stuff. This is used for 
	SELECT T_SID_AND_DESCRIPTION_ROW(0, maps_to_ind_sid, pi.description)
	  BULK COLLECT INTO v_ind_list
	  FROM pending_ind pi
	 WHERE maps_to_ind_sid IS NOT NULL
	   AND pending_ind_Id IN (
		SELECT column_value FROM TABLE(v_ind_tbl)
	);	
	datasource_pkg.Init(v_ind_list, in_include_stored_calcs);

	/**** figure out the actual dates we want to collect data for ****/
	
	-- work out if we're checking any tolerances, and what type (the type defines how much data we need to request)
	SELECT MIN(
		CASE tolerance_type
			WHEN csr_data_pkg.TOLERANCE_TYPE_NONE THEN 0
			WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_PERIOD THEN -in_interval_months
			WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR THEN -12
		END
		)min_tolerance_months
		INTO v_min_tolerance_months
	  FROM pending_ind
     WHERE pending_ind_Id IN (
		SELECT column_value FROM TABLE(v_ind_tbl)
	 );
	 
	 -- now compare to any offsets required by temporal functions in calculations 
	 SELECT LEAST( NVL(MIN(calc_start_dtm_adjustment),0), v_min_tolerance_months)
	   INTO v_start_dtm_adjustment
	   FROM TABLE(datasource_pkg.DependenciesTable);
	
	-- convert months to whole periods (and back to months) so that we cover an "whole" periodspan
	v_start_dtm_adjustment := FLOOR(v_start_dtm_adjustment / in_interval_months) * in_interval_months;

	-- now convert to proper dates and put into a cursor to pass back - all done!
	v_actual_start_dtm := ADD_MONTHS(in_start_dtm, v_start_dtm_adjustment);
	v_actual_end_dtm := in_end_dtm; -- no change here
	OPEN out_dates_cur FOR
		SELECT v_actual_start_dtm start_dtm, v_actual_end_dtm end_dtm
		  FROM DUAL;




	-- populate some cursors
	datasource_pkg.GetAggregateChildren(out_aggr_children_cur);
	datasource_pkg.GetIndDependencies(out_ind_depends_cur);

	/* We aim to just return useful pending region nodes, i.e. we try and find mapped
	 * regions wherever possible.
	 * 
	 *  Pending Region nodes that get selected:                                           
	 *                   __o_                      
	 *                  /    \                    
	 *                (x)     o                    
	 *                / \   / | \                  
	 *               .   .(o)(x)(x)                   
	 *                                             
	 *     x = mapped                            
	 *     o = unmapped          
	 *     . = nodes (mapped or unmapped)        
	 *    ( )= selected by the SQL                                          
	 */
	
	-- We need to consider situations where a PENDING_REGION doesn't map, but we need to do 
	-- calculations on it, e.g. Energy per FTE for Europe, where Europe isn't mapped to anything 
	-- in the main Region tree.
	--
	-- Fetch lower level region notes if the dates requested are outside the pending_period range 
	-- for this pending_dataset and if one or more of the pending_regions does not map to a 
	-- region_sid (i.e. if it did map then we could use pre-aggregated data from the VAL table).
	-- If the date range requested is in the pending_period_range then it'll all be pre-aggregated
	-- for us in pending_val_cache.

	SELECT COUNT(*) 
	  INTO v_unmapped_region_cnt 
	  FROM TABLE(v_region_tbl)x, pending_region pr
	 WHERE x.column_value = pr.pending_region_id
	   AND maps_to_region_sid IS NOT NULL;

	IF (v_actual_start_dtm < v_pp_start_dtm OR v_actual_end_dtm > v_pp_end_dtm)
		AND v_unmapped_region_cnt > 0
	THEN
		-- shove the leaf nodes from this query into a table so that we can select matching values
		SELECT DISTINCT pending_region_id
		  BULK COLLECT INTO v_region_nodes
		  FROM pending_region
		 WHERE pending_dataset_Id = in_pending_dataset_id
		   AND CONNECT_BY_ISLEAF = 1
		 START WITH pending_region_id IN (
			SELECT column_value FROM TABLE(v_region_tbl) 
			)
	   CONNECT BY PRIOR pending_region_id = parent_region_id
		   AND PRIOR maps_to_region_sid IS NULL;
	
		-- select a nicely structured tree representing how we aggregate these nodes into a cursor
		OPEN out_regions_cur FOR
			SELECT x.pending_region_id, description, x.maxlvl lvl, y.maps_to_region_sid,
				pending_Dataset_id, pos, parent_region_id
			  FROM (
				SELECT pending_region_id, MAX(lvl) maxlvl
			      FROM (
					SELECT pending_region_id, description, level lvl
					  FROM pending_region
					 WHERE pending_dataset_Id = in_pending_dataset_Id
					 START WITH pending_region_id IN (
						SELECT column_value FROM TABLE(v_region_tbl) 
					)
				   CONNECT BY PRIOR pending_region_id = parent_region_id
					   AND PRIOR maps_to_region_sid IS NULL
				)
				 GROUP BY pending_region_id
			  )x, (
				SELECT pending_region_Id, maps_to_region_sid, rownum rn, 
					description, pending_Dataset_id, pos, parent_region_id
				  FROM pending_region
				 WHERE pending_Dataset_id = in_pending_dataset_Id
				 START WITH parent_region_id IS NULL
			   CONNECT BY PRIOR pending_region_id = parent_region_Id
				 ORDER SIBLINGS BY POS             
			  )y
			WHERE x.pending_region_id = y.pending_region_id
			ORDER BY rn;
	ELSE
		-- shove the leaf nodes from this query into a table so that we can select matching values
		v_region_nodes := v_region_tbl;
		
		OPEN out_regions_cur FOR
			SELECT pending_region_id, description, 1 lvl, maps_to_region_sid, 
				pending_Dataset_id, pos, parent_region_id
			  FROM pending_region
			 WHERE pending_region_id IN (
			 	SELECT column_value FROM TABLE(v_region_tbl) 
			 );
	END IF;
		
	-- we return inds and pending_inds separately because pending_inds are specific to the 
	-- pending stuff, and the datasource code is intended to be more generic

	-- Rather than call datasource_pkg.GetAllIndDetails(out_inds_cur) we have a specific version 
	-- of inds_cur because we override description / tolerances etc with versions from pending_ind 
	-- wherever possible
	OPEN out_inds_cur FOR
		SELECT i.ind_sid, NVL(pi.description, i.description) description,	 
   			   NVL(NVL(i.scale, m.scale),0) scale,
   			   NVL(NVL(i.format_mask, m.format_mask),'#,##0') format_mask, 
   			   NVL(i.divisibility, NVL(m.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
   			   NVL(pi.aggregate, i.aggregate) aggregate, i.period_set_id, i.period_interval_id,
   			   i.do_temporal_aggregation, i.calc_description, i.calc_xml, 
      		   i.ind_type, i.calc_start_dtm_adjustment,
   			   NVL(m.description,'none') measure_description, i.measure_sid, NVL(pi.info_xml, i.info_xml) info_xml, i.start_month, i.gri, 
			   i.parent_sid, NVL(pi.pos, i.pos) pos, i.target_direction, i.active,
               CASE WHEN pi.tolerance_type IS NULL THEN i.pct_lower_tolerance ELSE pi.pct_lower_tolerance END pct_lower_tolerance,
               CASE WHEN pi.tolerance_type IS NULL THEN i.pct_upper_tolerance ELSE pi.pct_upper_tolerance END pct_upper_tolerance,
               NVL(pi.tolerance_type, i.tolerance_type) tolerance_type,
               i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
               i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
               i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key, i.calc_output_round_dp
		 FROM (
		 	SELECT dep_ind_sid
		 	  FROM TABLE(datasource_pkg.DependenciesTable)
		 	 UNION -- union eliminates any duplicates for us
		 	SELECT sid_id  
		 	  FROM TABLE(datasource_pkg.GetInds)
		     ) x, v$ind i, measure m, pending_ind pi
	     WHERE i.ind_sid = x.dep_ind_sid 
	       AND i.measure_sid = m.measure_sid(+) -- we pull indicators even if they have no measure - sometimes they have null values in pending_val because there are notes etc
           AND pi.maps_to_ind_sid(+) = i.ind_sid
		   AND pi.pending_dataset_id(+) = in_pending_dataset_id; -- must be from right dataset

	-- special cursor for pending inds
	OPEN out_pending_inds_cur FOR
		SELECT pi.pending_ind_id, pi.description, pi.val_mandatory, pi.note_mandatory, pi.file_upload_mandatory, pi.lookup_key,
			   pi.tolerance_type, pi.pct_upper_tolerance, pi.pct_lower_tolerance, pi.pending_dataset_Id,
			   pi.parent_ind_Id, pi.measure_sid, pi.maps_to_ind_sid, 
			   NVL(i.divisibility, NVL(mi.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
			   pi.pos, pi.allow_file_upload,
			   NVL(pi.aggregate, i.aggregate) aggregate, i.calc_xml, pi.element_type, NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) ind_type,
			   pi.format_xml, pi.read_only, pi.link_to_ind_id, pi.info_xml, NVL(pi.dp, m.scale) dp, pi.default_val_number, pi.default_val_string
		  FROM pending_ind pi, ind i, measure m, measure mi
		 WHERE pi.pending_dataset_id = in_pending_dataset_id
	       AND pi.app_sid = i.app_sid(+) AND pi.maps_to_ind_sid = i.ind_sid(+)
	       AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
	       AND pi.app_sid = m.app_sid(+) AND pi.measure_sid = m.measure_sid(+)
	       AND pi.pending_ind_id IN (
			SELECT column_value FROM TABLE(v_ind_tbl)
		);

	OPEN out_values_cur FOR
	    -- THE ORDER OF THESE MATTERS AS THE DATA READER IS HARD-CODED FOR SPEED (Credit360.Pending.PendingCalcRawValue constructor)
	    -- stuff from pending_val we need (might not be in our approval step, but might be needed for calculations)
		SELECT pp.start_dtm, pp.end_dtm, pv.pending_region_id, pi.pending_ind_Id, dsi.COLUMN_VALUE maps_to_ind_sid, pv.val_number,
			   1 priority
		  FROM TABLE(datasource_pkg.GetValueInds) dsi, pending_ind pi, pending_val pv, pending_period pp, TABLE(v_region_nodes)r, IND i
		 WHERE dsi.COLUMN_VALUE = pi.maps_to_ind_sid
		   AND pv.pending_ind_id = pi.pending_ind_id
		   AND pv.pending_region_id = r.column_value
		   AND pv.pending_period_id = pp.pending_period_id		        
		   AND pp.end_dtm > v_actual_start_dtm
		   AND pp.start_dtm < v_actual_end_dtm
		   -- special case - ignore stuff from pending_val, where it's a stored calc: values get written in here from
		   -- other bits of the code and we don't really want to use them
		   AND pi.maps_to_ind_sid = i.ind_sid(+)
		   AND NVL(i.ind_type, 0) != csr_data_pkg.IND_TYPE_STORED_CALC
		UNION 
		SELECT pp.start_dtm, pp.end_dtm, pvc.pending_region_id, pi.pending_ind_Id, dsi.COLUMN_VALUE maps_to_ind_sid, pvc.val_number,
			   2 priority
		  FROM TABLE(datasource_pkg.GetValueInds) dsi, pending_ind pi, pending_val_cache pvc, pending_period pp, TABLE(v_region_nodes)r  
		 WHERE dsi.COLUMN_VALUE = pi.maps_to_ind_sid
		   AND pvc.pending_ind_id = pi.pending_ind_id
		   AND pvc.pending_region_id = r.column_value
		   AND pvc.pending_period_id = pp.pending_period_id		        
		   AND pp.end_dtm > v_actual_start_dtm
		   AND pp.start_dtm < v_actual_end_dtm
		UNION 
		-- stuff from val we need (might not be in our approval step, but might be needed for calculations)
		SELECT v.period_start_dtm start_dtm, v.period_end_dtm end_dtm, pr.pending_region_id, null pending_ind_Id, dsi.COLUMN_VALUE maps_to_ind_sid, v.val_number,
			   3 priority
		  FROM TABLE(datasource_pkg.GetValueInds) dsi, val v, pending_region pr, TABLE(v_region_nodes)r 
		 WHERE dsi.COLUMN_VALUE = v.ind_sid
		   AND pr.maps_to_region_sid = v.region_sid
		   AND r.column_value = pr.pending_region_id
		   AND v.period_end_dtm > v_actual_start_dtm
		   AND v.period_start_dtm < v_actual_end_dtm
         -- sorted for running through the value normaliser
         ORDER BY maps_to_ind_sid, pending_region_id, start_dtm, priority, end_dtm DESC;

	-- values should be pre-aggregated for pending_val so pull from v_region_tbl, not v_region_nodes
	OPEN out_pending_val_cur FOR
		SELECT pv.pending_val_Id, pv.pending_ind_id, pv.pending_region_id, pp.pending_period_id, 
			   pp.start_dtm, pp.end_dtm, pv.val_number, pv.val_string, pv.approval_step_id,
			   pv.from_val_number, pv.from_measure_conversion_id, pi.maps_to_ind_sid, pv.note,
			   pvv.explanation variance_explanation, pv.action, 1 priority, 
			   (SELECT COUNT(*) FROM pending_val_file_upload pvfu WHERE pvfu.pending_val_id = pv.pending_val_id) file_upload_count
		  FROM pending_val pv, pending_val_variance pvv, pending_period pp, pending_region pr, pending_ind pi,
		  	   TABLE(v_region_tbl)vr, TABLE(v_ind_tbl)vi
		 WHERE pv.pending_ind_id = pi.pending_ind_id
		   AND pv.pending_region_id = pr.pending_region_id
		   AND pv.pending_period_id = pp.pending_period_id
		   AND pv.pending_val_id = pvv.pending_val_Id(+)
		   AND pp.start_dtm < v_actual_end_dtm
		   AND pp.end_dtm > v_actual_start_dtm
		   AND pr.pending_region_id = vr.column_value
		   AND pi.pending_ind_id = vi.column_value
		 UNION ALL -- we use UNION ALL so that we can include a CLOB
		SELECT null pending_val_Id, pvc.pending_ind_id, pvc.pending_region_id, pp.pending_period_id, 
			   pp.start_dtm, pp.end_dtm, pvc.val_number, null val_string, null approval_step_id,
			   null from_val_number, null from_measure_conversion_id, pi.maps_to_ind_sid, null note,
			   null variance_explanation, 'X' action, 2 priority, 0 file_upload_count
		  FROM pending_val_cache pvc, pending_period pp, pending_ind pi, pending_region pr,
		  	   TABLE(v_region_tbl)vr, TABLE(v_ind_tbl)vi
		 WHERE pvc.pending_ind_id = pi.pending_ind_id
		   AND pvc.pending_region_id = pr.pending_region_id
		   AND pvc.pending_period_id = pp.pending_period_id
		   AND pp.start_dtm < v_actual_end_dtm
		   AND pp.end_dtm > v_actual_start_dtm
		   AND pr.pending_region_id = vr.column_value
		   AND pi.pending_ind_id = vi.column_value
         -- sorted for running through the value normaliser
         ORDER BY pending_ind_id, pending_region_id, start_dtm, priority, end_dtm DESC;

	OPEN out_variance_cur FOR
		SELECT pv.pending_ind_id, pv.pending_region_id, pv.pending_period_id, pv.pending_val_id, 
			   variance, compared_with_start_dtm, compared_with_end_dtm, explanation,pp.start_dtm, pp.end_dtm
		  FROM pending_val pv, pending_val_variance pvv, pending_period pp,
		  	   TABLE(v_region_tbl)vr, TABLE(v_ind_tbl)vi
		 WHERE pv.pending_ind_id = vi.column_value
		   AND pv.pending_region_id = vr.column_value
		   AND pv.pending_period_id = pp.pending_period_id
		   AND pp.start_dtm < v_actual_end_dtm
		   AND pp.end_dtm > v_actual_start_dtm
		   AND pv.pending_val_id = pvv.pending_val_id;
         --ORDER BY pv.pending_val_id;
         --  AND pi.maps_to_ind_sid IS NULL -- exclude mapped inds (we've got mapped inds already) 
         -- ignore the above - we now pull all values that have been entered so we have measure conversion ids etc
         --ORDER BY pending_ind_id, pending_region_id, start_dtm, end_dtm DESC;

END;

PROCEDURE SetPendingValCacheValue(
	in_pending_ind_id		IN	pending_val_cache.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val_cache.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val_cache.pending_period_id%TYPE,
	in_val_number			IN	pending_val_cache.val_number%TYPE,
	in_write_aggr_job		IN	NUMBER
)
AS
BEGIN
	BEGIN
		INSERT INTO PENDING_VAL_CACHE
			(pending_ind_id, pending_region_Id, pending_period_id, val_number)
		VALUES
			(in_pending_ind_id, in_pending_region_id, in_pending_period_id, in_val_number);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE PENDING_VAL_CACHE
			   SET val_number = in_val_number
			 WHERE pending_ind_id = in_pending_ind_id
			   AND pending_region_id = in_pending_region_id
			   AND pending_period_id = in_pending_period_id;
	END;
	
	IF in_write_aggr_job = 1 THEN
		INSERT INTO pvc_region_recalc_job 
			(pending_ind_id, pending_dataset_id)
		 	SELECT pending_ind_id, pending_dataset_Id
		 	  FROM pending_ind 
	 		 WHERE pending_ind_id = in_pending_ind_id
	 		   AND aggregate IN ('SUM','FORCE SUM', 'AVERAGE') -- these are the only types we aggregate at the moment for pending
			 MINUS
			SELECT pending_ind_id, pending_dataset_Id FROM pvc_region_recalc_job
	 		 WHERE processing = 0
			   AND pending_ind_id = in_pending_ind_id;
	END IF;
END;



/*

BUG: 
Global -> EU (in pending_region)
       -> USA (in pending_region)
            -> Pacific NW (not in pending_region)
            
Elec per FTE = Elec / FTE

If you change Elec for Pacific NW, then it SHOULD cause a pending stored recalc for USA,
but it doesn't because Pacific NW isn't in the pending_region tree and when the value 
aggregator writes to USA, it doesn't write any jobs

*/

PROCEDURE AggregateUpTree(
	in_collate_region_id	IN		pending_region.pending_region_id%TYPE,
	in_log_table			IN OUT	T_RECALC_LOG_TABLE
)
AS
	v_pending_dataset_id		pending_dataset.pending_dataset_id%TYPE;
	-- get all values from the pending_val, pending_val_cache, and val
	CURSOR c_ir IS	
		-- from the main val table (we assume divisibility = DIVISIBILITY_DIVISIBLE)
		SELECT pi.pending_ind_id, pr.pending_region_Id, 1 priority, pr.parent_region_id, pi.description ind_description, pr.description region_description, 
			   csr_data_pkg.DIVISIBILITY_DIVISIBLE divisibility, pp.start_dtm, pp.end_dtm, pp.END_DTM-pp.START_DTM duration, pi.aggregate, val_number, pv.pending_val_id src_val_id,
			   pp.start_dtm pp_start_dtm
		  FROM PENDING_VAL pv, PENDING_REGION pr, PVC_REGION_RECALC_JOB rrj, PENDING_IND pi, PENDING_PERIOD pp, IND i
		 WHERE pv.pending_ind_id = pi.pending_ind_id
		   AND pv.pending_region_id = pr.pending_region_id
		   AND pv.pending_period_id = pp.pending_period_id
		   AND rrj.pending_ind_id = pi.pending_ind_id
		   AND rrj.pending_dataset_Id = v_pending_dataset_Id
		   AND rrj.processing = 1 -- so we don't get muddled up and do some that have come in half way through 
		   AND pr.parent_region_id = in_collate_region_id
		   AND pi.measure_sid IS NOT NULL -- no point in touching things that are Folders and not indicators with numbers
		   AND pi.AGGREGATE IN ('FORCE SUM','SUM','AVERAGE')
		   -- special case - ignore stuff from pending_val, where it's a stored calc: values get written in here from
		   -- other bits of the code and we don't really want to use them
		   AND pi.maps_to_ind_sid = i.ind_sid(+)
		   AND NVL(i.ind_type, 0) != csr_data_pkg.IND_TYPE_STORED_CALC
		 UNION -- from the pending_val_Cache (we assume divisibility = DIVISIBILITY_DIVISIBLE)
		SELECT pi.pending_ind_id, pr.pending_region_Id, 2 priority, pr.parent_region_id, pi.description ind_description, pr.description region_description,
			csr_data_pkg.DIVISIBILITY_DIVISIBLE divisibility, pp.start_dtm, pp.end_dtm, pp.END_DTM-pp.START_DTM duration, pi.aggregate, val_number, null src_val_id,
			pp.start_dtm pp_start_dtm
		  FROM PENDING_VAL_CACHE pvc, PENDING_REGION pr, PVC_REGION_RECALC_JOB rrj, PENDING_IND pi, PENDING_PERIOD pp
		 WHERE pvc.pending_ind_id = pi.pending_ind_id
		   AND pvc.pending_region_id = pr.pending_region_id
		   AND pvc.pending_period_id = pp.pending_period_id
		   AND rrj.pending_ind_id = pi.pending_ind_id
		   AND rrj.pending_dataset_Id = v_pending_dataset_Id
		   AND rrj.processing = 1 -- so we don't get muddled up and do some that have come in half way through 
		   AND pr.parent_region_id = in_collate_region_id
		   AND pi.measure_sid IS NOT NULL -- no point in touching things that are Folders and not indicators with numbers
		   AND pi.AGGREGATE IN ('FORCE SUM','SUM','AVERAGE')
		 UNION -- from VAL
		SELECT pi.pending_ind_id, pr.pending_region_Id, 3 priority, pr.parent_region_id, pi.description ind_description, pr.description region_description,
			   NVL(i.divisibility, mi.divisibility), v.period_start_dtm start_dtm, v.period_end_dtm end_dtm, v.period_END_DTM-v.period_start_DTM duration, pi.aggregate, val_number, val_id src_val_id,
			   pp.start_dtm pp_start_dtm
		  FROM val v, pending_region pr, pvc_region_recalc_job rrj, pending_ind pi, pending_period pp, pending_dataset pd, ind i, measure mi
		 WHERE v.ind_sid = i.ind_sid
		   AND i.ind_sid = pi.maps_to_ind_sid
		   AND v.region_sid = pr.maps_to_region_sid
		   AND v.period_start_dtm < pp.end_dtm
		   AND v.period_end_dtm > pp.start_dtm
		   AND pi.pending_dataset_id = pd.pending_dataset_Id
		   AND pr.pending_dataset_id = pd.pending_dataset_Id
		   AND pp.pending_dataset_id = pd.pending_dataset_Id
		   AND rrj.pending_ind_id = pi.pending_ind_id
		   AND rrj.pending_dataset_Id = v_pending_dataset_Id
		   AND rrj.processing = 1 -- so we don't get muddled up and do some that have come in half way through 
		   AND pr.parent_region_id = in_collate_region_id
		   AND pi.measure_sid IS NOT NULL -- no point in touching things that are Folders and not indicators with numbers
		   AND pi.aggregate iN ('FORCE SUM','SUM','AVERAGE')
		   AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
		   -- all things being equal, sort so that the lower priority with the same start date comes first
		 ORDER BY pending_ind_id, pp_START_DTM, pending_region_id, start_dtm, priority, duration DESC;

	r							c_ir%ROWTYPE;
	v_collate_ind_id 			pending_ind.pending_ind_id%TYPE;
	v_collate_region_id 		pending_region.pending_region_id%TYPE;
	v_collate_aggregate_type	ind.aggregate%TYPE;
	v_collate_divisibility 		ind.divisibility%TYPE;


	v_collate_val_number		pending_val.val_number%TYPE;
	v_collate_val_duration		NUMBER;
	v_collate_val_is_est		BOOLEAN;
	v_collate_val_is_null		BOOLEAN;
	v_collate_most_recent_dtm	DATE;
	v_source_raw_values			VARCHAR2(1024);


	v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_duration					NUMBER;
	
	v_current_end_dtm			DATE;
	v_val						val.val_number%TYPE;
                        		
	v_old_val_number			val.val_number%TYPE;
	
	v_period_duration 			NUMBER;
BEGIN
	-- figure out the pending_dataset_Id
	SELECT pending_dataset_id
	  INTO v_pending_dataset_id
	  FROM pending_region
	 WHERE pending_region_id = in_collate_region_id;

	dbms_output.put_line('==> Summing region '||in_collate_region_id||' <--');
 	OPEN c_ir;
	FETCH c_ir INTO r;
	dbms_output.put_line('*** fetched '||r.start_dtm||' to '||r.end_dtm||' for region '||r.pending_region_id||' = '||r.val_number);
	-- sort order gives us 'biggest' timeperiod first
	
	WHILE c_ir%FOUND
	LOOP
		dbms_output.put_line('IND '||r.ind_description);
		v_collate_ind_id := r.pending_ind_id;
		v_collate_aggregate_type := r.aggregate;
		v_collate_divisibility := r.divisibility;
		
		FOR rp IN (
			SELECT pending_period_Id, start_dtm, end_dtm
			  FROM pending_period
			 WHERE pending_Dataset_id = v_pending_dataset_id
			 ORDER BY start_dtm
		)
		LOOP		
			dbms_output.put_line('PERIOD '||rp.start_dtm||' -> '||rp.end_dtm);
			-- for each period in the period span
			-- eat irrelevant historic data in the cursor
			WHILE c_ir%FOUND 
				--AND r.pending_region_id = v_collate_region_id  
				AND r.pending_ind_id = v_collate_ind_id
				AND r.end_dtm <= rp.start_dtm
			LOOP
				dbms_output.put_line('Eating data start_dtm '||r.start_dtm);
				FETCH c_ir INTO r;	-- try next row								
			END LOOP;
			
			-- ASSUMPTION: data ends after our seek period start
			v_collate_val_number := 0;
			v_collate_val_duration := 0;
			v_collate_val_is_est := false;
			v_collate_val_is_null := true; -- assume null unless proved otherwise
			v_collate_most_recent_dtm := DATE '1900-01-01'; 
			v_source_raw_values := '';

			dbms_output.put_line('aggregating...');

			-- aggregate data for period from reader
			<<period_aggregator>>
			WHILE c_ir%FOUND 
				--AND r.pending_region_id = v_collate_region_id  
				AND r.pending_ind_id = v_collate_ind_id
				AND r.start_dtm < rp.end_dtm
			LOOP
				-- Aggregate data from reader for output period
				-- crop date off either side of our period
				v_collate_region_id := r.pending_region_id;
				v_start_dtm := GREATEST(rp.start_dtm, r.start_dtm);
				v_end_dtm := LEAST(rp.end_dtm, r.end_dtm);
				-- get duration in days
				v_duration := v_end_dtm - v_start_dtm;

				dbms_output.put_line('  REGION '||r.region_description);
				dbms_output.put_line('  divisibility '||v_collate_divisibility);
				dbms_output.put_line('  dates '||v_start_dtm ||'->'||v_end_dtm||' - duration '||v_duration);

				-- set the actual value
				CASE v_collate_divisibility
				WHEN csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					-- if divisble, then get a proportional value for this period
					v_period_duration := r.end_dtm - r.start_dtm;
					dbms_output.put_line('  period duration '||v_period_duration);
					-- for val
					v_collate_val_number := v_collate_val_number + NVL(r.val_number,0) * v_duration / v_period_duration;
					-- is this estimated?
					IF v_period_duration != v_duration THEN
						v_collate_val_is_est := true;
					END IF;
			
				WHEN csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN
					-- we want to use the last value for the period
					-- e.g. Q1, Q2, Q3, Q4 << we take Q4 value
					v_collate_val_number := NVL(r.val_number,0);
					v_source_raw_values := ''; -- clear down - we'll add this one in in a tick
				
				WHEN csr_data_pkg.DIVISIBILITY_AVERAGE THEN
					-- if not divisible, then average this out over differing periods for val						
					v_collate_val_number := (v_collate_val_number * v_collate_val_duration + NVL(r.val_number,0) * v_duration) / (v_collate_val_number + v_duration);
					-- is this estimated?
					IF v_collate_val_duration != 0 THEN
						v_collate_val_is_est := true;
					END IF;
					v_collate_val_duration := v_collate_val_duration + v_duration;
				
				END CASE;
					

				-- mark as not null (or leave, maybe as null - depends!)
				IF r.val_number IS NOT NULL THEN
					v_collate_val_is_null := false;
				END IF;
				-- record the source of the number
				IF v_source_raw_values IS NOT NULL THEN
					v_source_raw_values := v_source_raw_values || ',';
				END IF;
				v_source_raw_values := v_source_raw_values || r.src_val_id;

				dbms_output.put_line('  v_collate_val_number = '||v_collate_val_number);
				dbms_output.put_line('  v_collate_val_duration = '||v_collate_val_duration);
				
				-- figure out most recent change (i.e. for things like 'show me stuff that has changed since...')				
				-- we wrap with NVL, so if it's the first one we use it
				--v_collate_most_recent_dtm := GREATEST(v_collate_most_recent_dtm, m_thisValue.ChangedDtm);

				-- what next? store this value away, or keep getting more data to build up the new value?
				-- no need for new numbers, we're busy enough with this one
				dbms_output.put_line('  rp.end_dtm = '||rp.end_dtm ||'; r.end_dtm = '||r.end_dtm);
				
				-- This line used to be in the C# code... is it required?
				--EXIT WHEN rp.end_dtm <= r.end_dtm;

				/* get some more data, but swallow anything which starts before the end of the
				   last data we shoved into our overall value for this period.
				   e.g.
				   J  F  M  A  M  J  J  A  (seek period is Jan -> end June)
				   |--------|        |     (used)
				   |     |-----|     |     (discarded) << or throw exception?
				   |        |--------|--|  (used - both parts)
				   |              |--|     (discarded) << or throw exception?
				*/
				-- eat_intermediate_data
				v_current_end_dtm := r.end_dtm;
				WHILE c_ir%FOUND 
					AND r.pending_region_id = v_collate_region_id
					AND r.pending_ind_id = v_collate_ind_id
					AND r.start_dtm < v_current_end_dtm
				LOOP
					dbms_output.put_line('  eating data: '||r.pending_region_id||', '||r.pending_ind_id||', r.start_dtm = '||r.start_dtm||'; v_current_end_dtm = '||v_current_end_dtm);
					--throw new Exception("Overlaps exist in data:");
					FETCH c_ir INTO r;
				END LOOP;
			END LOOP;
			-- store the value
			--Value v;
			IF v_collate_val_is_null THEN 
				-- TODO: if there's a default value, then use it	
				v_val := NULL;
				-- v = new Value((decimal)ind.DefaultNumericValue);
			ELSE
				--v = new Value(m_valNumber * regions[m_lastRegionSid].PctOwnership, ind.NullMeansNull, m_sourceRawValues);
				v_val := v_collate_val_number;
			END IF;
			dbms_output.PUT_LINE('STORING '||v_val);
			dbms_output.PUT_LINE('');
			-- save back to the database
			BEGIN
				INSERT INTO PENDING_VAL_CACHE
					(pending_ind_id, pending_region_Id, pending_period_id, val_number)
				VALUES
					(v_collate_ind_id, in_collate_region_id, rp.pending_period_id, v_val);
					-- conditionally log the change
				IF in_log_table IS NOT null THEN
					in_log_table.extend();
					in_log_table(in_log_table.COUNT) := T_RECALC_LOG_ROW(v_collate_ind_Id, in_collate_region_id, rp.pending_period_id, v_val);
				END IF;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					SELECT val_number
					  INTO v_old_val_number
					  FROM pending_VAL_CACHE
					 WHERE pending_ind_id = v_collate_ind_id
					   AND pending_region_id = in_collate_region_id
					   AND pending_period_id = rp.pending_period_id
					   FOR UPDATE;
					UPDATE PENDING_VAL_CACHE
					   SET val_number = v_val
					 WHERE pending_ind_id = v_collate_ind_id
					   AND pending_region_id = in_collate_region_id
					   AND pending_period_id = rp.pending_period_id
				 	RETURNING val_number INTO v_val; -- if it's been rounded or anything then we need the rounded version to compare with what went before
					 /* can we use returning "previous" into ? like in :OLD.foo in a trigger? */
					 -- if it differs then conditionally log the change
					IF v_old_val_number != v_val AND in_log_table IS NOT null THEN
						in_log_table.extend();
						in_log_table(in_log_table.COUNT) := T_RECALC_LOG_ROW(v_collate_ind_Id, in_collate_region_id, rp.pending_period_id, v_val);
					END IF;
			END;
		END LOOP;
		-- skip to start of next region / ind set (if not already at start)
		WHILE c_ir%FOUND 
			AND r.pending_region_id = v_collate_region_id
			AND r.pending_ind_id = v_collate_ind_id
		LOOP
			FETCH c_ir INTO r; -- next row
		END LOOP;
	END LOOP;
END;


PROCEDURE AggregatePendingDataset(
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_log_changes			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_tbl 	T_RECALC_LOG_TABLE := null;
BEGIN
	UPDATE pvc_region_recalc_job
	   SET processing = 1 
	 WHERE pending_dataset_id = in_pending_dataset_id;

	IF in_log_changes = 1 THEN
		v_log_tbl := T_RECALC_LOG_TABLE();
	END IF;

	FOR r IN (
		SELECT pending_region_id, parent_region_id, LEVEL so_level
		  FROM pending_region 
		 WHERE CONNECT_BY_ISLEAF = 0 -- ignore leaf nodes
		   AND pending_dataset_id = in_pending_dataset_id
		 START WITH parent_region_id IS NULL
		CONNECT BY PRIOR pending_region_id = parent_region_id
		 ORDER BY SO_LEVEL DESC, parent_region_id, pending_region_id
	)
	LOOP
		AggregateUpTree(r.pending_region_Id, v_log_tbl);
	END LOOP;

	DELETE FROM pvc_region_recalc_job
	 WHERE processing = 1 
	   AND pending_dataset_id = in_pending_dataset_id;

	IF in_log_changes = 0 THEN
		-- create a blank table if we weren't logging changes
		v_log_tbl := T_RECALC_LOG_TABLE();
	END IF;
	   
	OPEN out_cur FOR
		SELECT * 
		  FROM TABLE(v_log_tbl);
END;

PROCEDURE AggregateAllPendingDatasets
AS
	v_cur					security_pkg.T_OUTPUT_CUR;
BEGIN
	FOR r IN (
		select distinct pending_dataset_Id
		  from pvc_region_recalc_job rrj
	)
	LOOP
		AggregatePendingDataset(r.pending_dataset_id, 0, v_cur);		
	END LOOP;
END;	

END pending_datasource_pkg;
/
