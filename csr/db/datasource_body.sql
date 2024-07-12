-- This code is legacy and only used by pending, newer code uses val_datasource_pkg or stored_calc_datasource_body

CREATE OR REPLACE PACKAGE BODY CSR.datasource_pkg AS
-- We need to work out all the indicators we need to retrieve data for.
-- These are going to be all the indicators for this approval step AND
-- any other indicators that these indicators might reference in calculations.

-- For calculations we also need to know all the dependencies so that
-- if a user updates a value for an indicator in a dataset we can ripple a change 
-- through -> or is this going to be too hard?

-- First we need to write out a list of top level Indicators we need to pull
-- Then, we need to build a list of  CALC_IND_SID, IND_SID dependencies for these indicators
-- Then we need to get values for both the top level indicators AND the dependency inds

/* this is a rewrite of the calc_pkg which is more efficient
 * because it uses hierarchical queries. I didn't want to swap
 * out the old code because some of it behaves in quirky ways,
 * so changing it would mean a load of other changes to legacy
 * code, such as CSRCalc, RecalcStoredCalc,
 * Credit360.Schema.DataSource etc
 */

-- return full info on all indicators: inds + their dependencies
PROCEDURE GetAllIndDetails(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	OPEN out_cur FOR
		SELECT i.ind_sid, i.description,
	   		   NVL(i.scale, m.scale) scale,
	   		   NVL(i.format_mask, m.format_mask) format_mask, 
	   		   NVL(i.divisibility, m.divisibility) divisibility, i.aggregate, 
	   		   i.period_set_id, i.period_interval_id,
	   		   i.do_temporal_aggregation, i.calc_description, i.calc_xml, i.ind_type,
	   		   LEAST(i.calc_start_dtm_adjustment, vi.calc_start_dtm_adjustment) calc_start_dtm_adjustment,
			   GREATEST(i.calc_end_dtm_adjustment, vi.calc_end_dtm_adjustment) calc_end_dtm_adjustment,
	   		   m.description measure_description, i.measure_sid, i.info_xml, i.start_month, i.gri, 
			   i.parent_sid, pos, i.target_direction, i.active,i.pct_lower_tolerance, i.pct_upper_tolerance, i.tolerance_type, 
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.normalize,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.prop_down_region_tree_sid, 
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.is_system_managed, i.lookup_key,
			   i.calc_output_round_dp
		  FROM (SELECT vi.column_value ind_sid,
		               NVL(MIN(dep.calc_start_dtm_adjustment), 0) calc_start_dtm_adjustment, 
		               NVL(MIN(dep.calc_end_dtm_adjustment), 0) calc_end_dtm_adjustment
		  		  FROM TABLE(m_value_ind_sids) vi, TABLE(m_dependencies) dep
		  		 WHERE vi.column_value = dep.seek_ind_sid(+)
		  	  GROUP BY vi.column_value) vi, 
		  		v$ind i, measure m
	      WHERE i.ind_sid = vi.ind_sid AND i.measure_sid = m.measure_sid(+);
END;

-- return full info on all gas factors
PROCEDURE GetAllGasFactors(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	OPEN out_cur FOR
		SELECT f.factor_type_id, f.gas_type_id,
			   f.region_sid, f.geo_country, f.geo_region, f.egrid_ref,
			   f.start_dtm, f.end_dtm, f.std_measure_conversion_id, f.value
		  FROM factor_type ft, factor f
		 WHERE ft.factor_type_id IN (SELECT i.factor_type_id
		 							   FROM ind i, TABLE(m_value_ind_sids) il
		 							  WHERE i.ind_sid = il.column_value)
		   AND ft.factor_type_id = f.factor_type_id
		   AND f.is_selected = 1
		 ORDER BY f.start_dtm;
END;

PROCEDURE GetIndDependencies(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	OPEN out_cur FOR
		SELECT seek_ind_sid calc_ind_sid, dep_ind_sid ind_sid, lvl
		  FROM TABLE(m_dependencies)
		 ORDER BY lvl DESC;
END;

PROCEDURE GetAggregateChildren(
	out_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	OPEN out_cur FOR
		-- now make a list of parent and child nodes that we'll need for aggregate functions
		SELECT DISTINCT i.parent_sid, i.ind_sid 
          FROM calc_dependency cd,  ind i, (
           	SELECT DISTINCT seek_ind_sid FROM TABLE(datasource_pkg.DependenciesTable)
           	)d
         WHERE dep_type = csr_data_pkg.DEP_ON_CHILDREN
       	   AND cd.ind_sid = i.parent_sid
           AND cd.calc_ind_sid = d.seek_ind_sid
           AND i.map_to_ind_sid IS NULL
           AND i.measure_sid IS NOT NULL
         ORDER BY parent_Sid;
END;

PROCEDURE GetRegionPctOwnership(
	out_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
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

FUNCTION GetInds RETURN T_SID_AND_DESCRIPTION_TABLE
AS
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_ind_sids;	
END;

FUNCTION GetValueInds RETURN security.T_SID_TABLE
AS
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_value_ind_sids;	
END;

FUNCTION DependenciesTable RETURN T_DATASOURCE_DEP_TABLE
AS
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_dependencies;	
END;


-- include_stored_calcs measn that the code will drill into stored
-- calculations and return all their dependencies too. This is needed
-- if you are working out stored calculations (obviously!) OR if you
-- are working out values from the ground-up (as in the PendingDataSource).
PROCEDURE Init(
	in_ind_list				IN	T_SID_AND_DESCRIPTION_TABLE,
	in_include_stored_calcs	IN	NUMBER
)
AS
	t_inds_used			T_DATASOURCE_DEP_TABLE;
	v_just_ind_sids 	security_pkg.T_SID_IDS;
	v_incl_stored_type	ind.ind_type%TYPE := -1; -- a type that won't exist, so has no impact in IN expression
BEGIN
	IF in_include_stored_calcs = 1 THEN
		v_incl_stored_type := csr_data_pkg.IND_TYPE_STORED_CALC; 
	END IF;
	
	-- mark as initialised
	m_is_initialised := true;
	
	-- take a copy of the indicators
	SELECT T_SID_AND_DESCRIPTION_ROW(pos, sid_id, description)
	  BULK COLLECT INTO m_ind_sids
	  FROM TABLE(in_ind_list);
	  
	-- TODO: return stored calc dependencies ONLY -> calculation optimisation
	  
    -- take a copy of all things that these indicators use into a dependencies table
    
    -- TODO: this should be swapped for select * from table(calc_pkg.GetAllCalcsUsingIndAsTable(292422))
	-- would possibly be faster (although the code is clunkier) 



	-- Now make a list of all inds we want to get values for.	
	-- if we've specified "incl_stored_calcs", then we're going to 
	-- calculate stored calcs ourselves, so don't fetch them into this list	
	SELECT sid_id
	  BULK COLLECT INTO v_just_ind_sids
	  FROM TABLE(in_ind_list);
	  
	t_inds_used := Calc_Pkg.GetAllIndsUsedAsTable(v_just_ind_sids, in_include_stored_calcs);
	
	SELECT T_DATASOURCE_DEP_ROW(seek_ind_sid, calc_dep_type, dep_ind_sid, /*+  USE_NL (dep,i) */ MAX(lvl),
	                            MIN(calc_start_dtm_adjustment), MAX(calc_end_dtm_adjustment))
	  BULK COLLECT INTO m_dependencies
	  FROM TABLE(t_inds_used) dep
	 GROUP BY seek_ind_sid, calc_dep_type, dep_ind_sid; --ORDER BY max_lvl DESC;
	  
	SELECT dep_ind_sid
	  BULK COLLECT INTO m_value_ind_sids
	  FROM (	  	
		SELECT dep_ind_sid
		  FROM TABLE(m_dependencies)
		 UNION -- effectively does a distinct
		SELECT sid_id
		  FROM TABLE(m_ind_sids)
	 );
END;

PROCEDURE Dispose
AS
BEGIN
	-- tidy up 
	SELECT null
	  BULK COLLECT INTO m_value_ind_sids
	  FROM DUAL
	 WHERE 1 = 0;
	
	SELECT T_SID_AND_DESCRIPTION_ROW(null, null, null)
	  BULK COLLECT INTO m_ind_sids
	  FROM DUAL
	 WHERE 1 = 0;
	 
	SELECT T_DATASOURCE_DEP_ROW(null, null, null, null, null, null)
	  BULK COLLECT INTO m_dependencies
	  FROM DUAL
	 WHERE 1 = 0;
	 
	-- mark as not initialised
	m_is_initialised := false;
END;


END datasource_pkg;
/
