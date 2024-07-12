CREATE OR REPLACE PACKAGE BODY CSR.initiative_grid_pkg IS

PROCEDURE GetBaseData(
	out_flow_states			OUT SYS_REFCURSOR,
	out_rag_statuses		OUT SYS_REFCURSOR,
	out_metrics         	OUT SYS_REFCURSOR,
	out_metric_conversions	OUT SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: how do we control security on this lot? 

	OPEN out_flow_states FOR
		SELECT DISTINCT fs.flow_state_id, fs.label, fs.state_colour, fs.lookup_key, fs.pos,
			   f.flow_sid, f.label flow_label
	      FROM flow_state fs
		  JOIN flow f ON fs.flow_sid = f.flow_sid
	      JOIN initiative_project ip ON fs.flow_sid = ip.flow_sid
	     WHERE fs.is_deleted = 0
	     ORDER BY fs.pos;

	OPEN out_rag_statuses FOR
	    SELECT rs.rag_status_id, rs.colour, rs.label, rs.lookup_key
	      FROM initiative_project_rag_status iprs
	      JOIN rag_status rs ON iprs.rag_status_id = rs.rag_status_id AND iprs.app_sid = rs.app_sid
	     GROUP BY rs.rag_status_id, rs.colour, rs.label, rs.lookup_key
	     ORDER BY MIN(iprs.pos);

	-- we do a weird join to proj_initiative_metric because oddly "update_per_period" is on this table. I can see _no_
	-- reason for wanting a metric per period on one project but not on another. Probably needs moving around. For now
	-- we go with the crap hack...
	OPEN out_metrics FOR
	    SELECT DISTINCT im.initiative_metric_id, im.lookup_key, m.measure_sid, m.description measure_description, im.per_period_duration, im.one_off_period, im.is_during,
	        im.is_running, im.is_rampable, im.label, NVL(im.divisibility, m.divisibility) divisibility, m.format_mask
	      FROM initiative_metric im 
	      JOIN measure m ON im.measure_sid = m.measure_sid AND im.app_sid = m.app_sid
	      JOIN project_initiative_metric pim ON im.initiative_metric_id = pim.initiative_metric_id AND im.app_sid = pim.app_sid 
	      	AND pim.update_per_period = 0 -- XXX: hmm dickie suggested this was right - we don't do updates per period ATM so probably true
	     ORDER BY im.label;

	-- return all measure conversions
	OPEN out_metric_conversions FOR
		SELECT DISTINCT m.measure_sid, -1 measure_conversion_id, m.description, NULL sort_by
		  FROM initiative_metric im
		  JOIN measure m ON im.measure_sid = m.measure_sid AND im.app_sid = m.app_sid
		 UNION
		SELECT DISTINCT m.measure_sid, mc.measure_conversion_id, mc.description, mc.description sort_by
		  FROM initiative_metric im
		  JOIN measure m ON im.measure_sid = m.measure_sid AND im.app_sid = m.app_sid
		  JOIN measure_conversion mc ON m.measure_sid = mc.measure_sid AND m.app_sid = mc.app_sid
		 ORDER BY measure_sid, sort_by NULLS FIRST; -- put the base unit first
END;

PROCEDURE INTERNAL_PrepMyInitiatives
AS
BEGIN
	-- play safe
	DELETE FROM temp_initiative;

	-- Select the initiatives we want to return information for
	INSERT INTO temp_initiative (initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, flow_state_colour, flow_state_pos, active, is_editable, owner_sid)
		SELECT initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key,
			flow_state_colour, flow_state_pos, active, MAX(is_editable), MIN(owner_sid) owner_sid
	      FROM v$my_initiatives
	     GROUP BY initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, flow_state_colour, flow_state_pos, active;
END;

PROCEDURE INTERNAL_GetMyInitiatives(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics OUT  SYS_REFCURSOR
)
AS
	v_t_initiatives			T_INITIATIVE_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_DATA_ROW (
		initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key,
		flow_state_colour, flow_state_pos, is_editable, active, owner_sid, pos
	)
	  BULK COLLECT INTO v_t_initiatives
	  FROM temp_initiative;

	OPEN out_cur FOR
		SELECT i.initiative_sid, i.name, i.internal_ref,
			i.project_sid, ip.icon project_icon, ip.name project_name, i.parent_sid, 
			i.project_start_dtm, i.project_end_dtm, i.running_start_dtm, i.running_end_dtm,
			i.fields_xml, i.created_dtm,
			i.is_ramped,
			i.flow_sid, i.flow_item_id, mi.flow_state_id, mi.flow_state_label, mi.flow_state_lookup_key, mi.flow_state_colour, mi.flow_state_pos, mi.is_editable,
			mi.active,
			i.created_by_sid, mi.owner_sid,
			rs.rag_status_id, rs.label rag_status_label, rs.colour rag_status_colour,
			NVL(cc.cnt,0) comment_count
		  FROM initiative i
		  JOIN TABLE(v_t_initiatives) mi ON i.initiative_sid = mi.initiative_sid
		  JOIN initiative_project ip ON i.project_sid = ip.project_sid 
		  JOIN flow_State fs ON mi.flow_state_id = fs.flow_state_id
		  LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
		  LEFT JOIN (
		  		-- ick - maybe move to a separate cursor if it's slow
		  		SELECT initiative_sid, COUNT(*) cnt
		  		  FROM initiative_comment
		  		 WHERE initiative_sid IN (
		  		 	SELECT initiative_sid FROM TABLE(v_t_initiatives)
		  		 )
		  		 GROUP BY initiative_sid
		  )cc ON i.initiative_sid = cc.initiative_sid
		 ORDER BY mi.pos, fs.pos, i.internal_ref desc;

	OPEN out_regions FOR
		SELECT ti.initiative_sid, r.region_sid, r.description, r.region_ref
		  FROM TABLE(v_t_initiatives) ti
		  JOIN initiative_region ir ON ti.initiative_sid = ir.initiative_sid
		  JOIN region rgn ON rgn.region_sid = ir.region_sid AND rgn.app_sid = ir.app_sid -- very slow joining init_region to v$region for some reason
		  JOIN v$region r ON r.region_sid = rgn.region_sid AND r.app_sid = rgn.app_sid;

	OPEN out_tags FOR
		SELECT it.initiative_sid, t.tag_id, t.tag
		  FROM initiative_tag it
		  JOIN v$tag t ON it.tag_id = t.tag_id AND it.app_sid = t.app_sid
		 WHERE it.initiative_sid in (
		 	SELECT initiative_sid FROM TABLE(v_t_initiatives)
		 );

	OPEN out_users FOR
		SELECT iu.initiative_sid, iu.user_sid, cu.full_name, cu.email, iu.initiative_user_group_id
		  FROM initiative_user iu
		  JOIN csr_user cu ON iu.user_sid = cu.csr_user_sid AND iu.app_sid = cu.app_sid
		 WHERE iu.initiative_sid in (
		 	SELECT initiative_sid FROM TABLE(v_t_initiatives)
		 );

	OPEN out_metrics FOR		
		SELECT imv.initiative_sid, im.initiative_metric_id, imv.val
		  FROM initiative_metric im
		  JOIN initiative_metric_val imv ON im.initiative_metric_id = imv.initiative_metric_id AND im.app_sid = imv.app_sid
		 WHERE imv.initiative_sid IN (
			SELECT initiative_sid FROM TABLE(v_t_initiatives) 
		 );
		  --AND im.lookup_key IS NOT NULL; -- shoudn't we map by the ID? the original thinking was that it's user definable templates per column done in Javascript so lookup Keys would be needed
		  -- csr.initiative_pkg.GetkeyedMetrics gets called by myInitiatives to return this list so that would need tweaking too.
END;

PROCEDURE GetMyInitiatives(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics	OUT  SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_PrepMyInitiatives;
	INTERNAL_GetMyInitiatives(out_cur, out_regions, out_tags, out_users, out_metrics);
END;

-- Factored out the bit that selects the initiatives (in the calling procedure) 
-- from the bit that gets the data (in this procedure)
PROCEDURE INTERNAL_GetMyInitsForMet(
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS, -- -1 == null as nullable arrays not supported by NPSL.DataAccess
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR
)
AS
	v_metric_id_table			security.T_ORDERED_SID_TABLE;
	v_conv_id_table				security.T_ORDERED_SID_TABLE;
	v_t_init_aggr_val_table		T_INITIATIVE_AGGR_VAL_DATA_TABLE;
	v_t_init_metric_data_table	T_INITIATIVE_METRIC_ID_DATA_TABLE;
BEGIN
	
	-- play safe
	DELETE FROM temp_initiative_aggr_val;
	DELETE FROM temp_initiative_sids;
	DELETE FROM temp_initiative_metric_ids;
	
	v_metric_id_table := security_pkg.SidArrayToOrderedTable(in_metric_ids);
	v_conv_id_table := security_pkg.SidArrayToOrderedTable(in_measure_conversion_ids);

	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT initiative_sid
		  FROM temp_initiative;

	-- MEASURE_CONVERSION_ID isn't used by INTERNAL_PrepAggrData but it helps us later
	INSERT INTO temp_initiative_metric_ids (initiative_metric_id, measure_conversion_id)
		SELECT m.sid_id, CASE WHEN c.sid_id = -1 THEN NULL ELSE c.sid_id END
		  FROM TABLE(v_metric_id_table) m
		  JOIN TABLE(v_conv_id_table) c ON m.pos = c.pos;
	
	initiative_aggr_pkg.INTERNAL_PrepAggrData;
    
	INTERNAL_GetMyInitiatives(out_cur, out_regions, out_tags, out_users, out_metrics);
	
	SELECT T_INITIATIVE_AGGR_VAL_DATA_ROW(initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
	  BULK COLLECT INTO v_t_init_aggr_val_table
	  FROM temp_initiative_aggr_val;
	  
	SELECT T_INITIATIVE_METRIC_ID_DATA_ROW(initiative_metric_id, measure_conversion_id)
	  BULK COLLECT INTO v_t_init_metric_data_table
	  FROM temp_initiative_metric_ids;
	
	OPEN out_vals FOR
	    SELECT v.initiative_sid, v.initiative_metric_id, v.region_sid, v.start_dtm, v.end_dtm, 
	    	ROUND(POWER((v.val_number - COALESCE(mc.c, mcp.c, 0)) / COALESCE(mc.a, mcp.a, 1), 1 / COALESCE(mc.b, mcp.b, 1)), 10) val_number
	      FROM TABLE(v_t_init_aggr_val_table) v
	      JOIN TABLE(v_t_init_metric_data_table) tim ON v.initiative_metric_id = tim.initiative_metric_id 
	      LEFT JOIN measure_conversion mc ON tim.measure_conversion_id = mc.measure_conversion_id 
	      LEFT JOIN measure_conversion_period mcp 
	      	ON mc.measure_conversion_id = mcp.measure_conversion_id 
	       AND mc.app_sid = mcp.app_sid 
	       AND (v.start_dtm >= mcp.start_dtm OR mcp.start_dtm IS NULL)
	       AND (v.end_dtm < mcp.end_dtm OR mcp.end_dtm IS NULL)
	     WHERE v.start_dtm >= in_start_dtm AND v.end_dtm <= in_end_dtm;
END;

PROCEDURE GetMyInitiativesForMetrics(
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS, -- -1 == null as nullable arrays not supported by NPSL.DataAccess
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_PrepMyInitiatives;
	INTERNAL_GetMyInitsForMet(
		in_metric_ids,
		in_measure_conversion_ids,
		in_start_dtm,
		in_end_dtm,
		out_cur,
		out_regions,
		out_tags,
		out_users,
		out_metrics,
		out_vals
	);	
END;

-- get initiatives for a specific teamroom
PROCEDURE GetTeamroomInitiatives(
	in_teamroom_sid		IN	 security_pkg.T_SID_ID,
	out_cur 			OUT	 SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the teamroom with sid '||in_teamroom_sid);
	END IF;	

	-- uses v$my_intiatives so no need for further security checks
	DELETE FROM temp_initiative;

	INSERT INTO temp_initiative (initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, flow_state_colour, flow_state_pos, is_editable, active, owner_sid)
		SELECT i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key,
			i.flow_state_colour, flow_state_pos, max(i.is_editable) is_editable, i.active, MIN(i.owner_sid) owner_sid
	      FROM v$my_initiatives i
		  JOIN teamroom_initiative ti ON i.initiative_sid = ti.initiative_sid AND i.app_sid = ti.app_sid
		 WHERE teamroom_sid = in_teamroom_sid
	     GROUP BY i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key, i.flow_state_colour, i.flow_state_pos, i.active;

	INTERNAL_GetMyInitiatives(out_cur, out_regions, out_tags, out_users, out_metrics);
END;


-- get initiatives for all teamrooms the user can access
PROCEDURE GetMyTeamroomInitiatives(
	out_cur 			OUT	 SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- uses v$my_intiatives so no need for further security checks
	DELETE FROM temp_initiative;

	INSERT INTO temp_initiative (initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, flow_state_colour, flow_state_pos, is_editable, active, owner_sid)
		SELECT i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key,
			i.flow_state_colour, i.flow_state_pos, i.is_editable, i.active, MIN(i.owner_sid) owner_sid
	      FROM v$my_initiatives i
		  JOIN teamroom_initiative ti ON i.initiative_sid = ti.initiative_sid AND i.app_sid = ti.app_sid
		 WHERE teamroom_sid IN (
		 	SELECT sid_id FROM TABLE(securableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Teamrooms'), security_pkg.PERMISSION_READ))
		 )
	     GROUP BY i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key, i.flow_state_colour, i.flow_state_pos, i.is_editable, i.active;

	INTERNAL_GetMyInitiatives(out_cur, out_regions, out_tags, out_users, out_metrics);

END;


PROCEDURE INTERNAL_PrepPropInitiatives(
	in_property_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM temp_initiative;
	
	INSERT INTO temp_initiative (initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, flow_state_colour, flow_state_pos, active, is_editable, owner_sid)
		SELECT i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key,
			i.flow_state_colour, i.flow_state_pos, i.active, MAX(i.is_editable), MIN(i.owner_sid)
	      FROM v$my_initiatives i
	      JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
	      JOIN (
		  	SELECT region_sid
		  	  FROM region
		  	  	-- TOOD: follow links
		  	  	START WITH region_sid = in_property_sid
		  	  	CONNECT BY PRIOR region_sid = parent_sid
		  ) rgns ON rgns.region_sid = ir.region_sid
	     WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	     GROUP BY i.initiative_sid, i.flow_state_id, i.flow_state_label, i.flow_state_lookup_key, i.flow_state_colour, i.flow_state_pos, active;
END;

PROCEDURE GetPropertyInitiatives(
	in_property_sid		IN	security_pkg.T_SID_ID,
	out_cur 			OUT  SYS_REFCURSOR,
	out_regions 		OUT  SYS_REFCURSOR,
	out_tags			OUT  SYS_REFCURSOR,
	out_users			OUT  SYS_REFCURSOR,
	out_metrics			OUT  SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_PrepPropInitiatives(in_property_sid);
	INTERNAL_GetMyInitiatives(
		out_cur, 
		out_regions, 
		out_tags, 
		out_users, 
		out_metrics
	);
END;

PROCEDURE GetMyPropInitiativesForMetrics(
	in_property_sid				IN	security_pkg.T_SID_ID,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS, -- -1 == null as nullable arrays not supported by NPSL.DataAccess
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR
)
AS
BEGIN	
	INTERNAL_PrepPropInitiatives(in_property_sid);
	INTERNAL_GetMyInitsForMet(
		in_metric_ids,
		in_measure_conversion_ids,
		in_start_dtm,
		in_end_dtm,
		out_cur,
		out_regions,
		out_tags,
		out_users,
		out_metrics,
		out_vals
	);	
END;


PROCEDURE INTERNAL_GetProps(
	out_props	OUT  SYS_REFCURSOR
)
AS
	v_t_initiatives			T_INITIATIVE_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_DATA_ROW (
		initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key,
		flow_state_colour, flow_state_pos, is_editable, active, owner_sid, pos
	)
	  BULK COLLECT INTO v_t_initiatives
	  FROM temp_initiative;

	OPEN out_props FOR
		WITH ir AS (
			SELECT ir.initiative_sid, ir.region_sid
		      FROM TABLE(v_t_initiatives) t
		      JOIN initiative_region ir ON t.initiative_sid = ir.initiative_sid
		)
		SELECT ir.initiative_sid, ir.region_sid, x.prop_sid, pr.description prop_desc, NVL(MAX(mp.is_editable), 0) is_editable
		  FROM (
			SELECT p.region_sid prop_sid, CONNECT_BY_ROOT (p.region_sid) region_sid
			  FROM region p
			 WHERE p.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
			  START WITH p.region_sid IN (
			    SELECT region_sid
			      FROM ir
			  )
			  CONNECT BY PRIOR p.parent_sid = p.region_sid
		) x
		  JOIN ir ON x.region_sid = ir.region_sid
		  JOIN v$region pr ON x.prop_sid = pr.region_sid
		  LEFT JOIN v$my_property mp ON x.prop_sid = mp.region_sid
		 GROUP BY ir.initiative_sid, ir.region_sid, x.prop_sid, pr.description
		 ORDER BY ir.initiative_sid, LOWER(pr.description)
		;
END;

PROCEDURE GetMyInitiativesWithProps(
	out_cur 	OUT  SYS_REFCURSOR,
	out_regions OUT  SYS_REFCURSOR,
	out_tags	OUT  SYS_REFCURSOR,
	out_users	OUT  SYS_REFCURSOR,
	out_metrics	OUT  SYS_REFCURSOR,
	out_props	OUT  SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_PrepMyInitiatives;
	INTERNAL_GetMyInitiatives(out_cur, out_regions, out_tags, out_users, out_metrics);
	INTERNAL_GetProps(out_props);
END;

PROCEDURE GetMyInitForMetricsWithProps(
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_measure_conversion_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm 				IN  DATE,
	in_end_dtm					IN  DATE,
	out_cur 					OUT SYS_REFCURSOR,
	out_regions 				OUT SYS_REFCURSOR,
	out_tags					OUT SYS_REFCURSOR,
	out_users					OUT SYS_REFCURSOR,
	out_metrics					OUT SYS_REFCURSOR,
	out_vals					OUT SYS_REFCURSOR,
	out_props					OUT SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_PrepMyInitiatives;
	INTERNAL_GetMyInitsForMet(
		in_metric_ids,
		in_measure_conversion_ids,
		in_start_dtm,
		in_end_dtm,
		out_cur,
		out_regions,
		out_tags,
		out_users,
		out_metrics,
		out_vals
	);
	INTERNAL_GetProps(
		out_props
	);
END;

END initiative_grid_pkg;
/
