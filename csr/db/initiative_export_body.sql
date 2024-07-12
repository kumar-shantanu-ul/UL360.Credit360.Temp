CREATE OR REPLACE PACKAGE BODY CSR.initiative_export_pkg
IS

PROCEDURE PrepExportViewFilter(
	in_text_filter			IN  VARCHAR2,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM temp_initiative_sids;
	-- restrict to just initiatives the user can see
	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT DISTINCT mi.initiative_sid
		  FROM v$my_initiatives mi
		  LEFT JOIN initiative i ON i.initiative_sid = mi.initiative_sid AND i.app_sid = mi.app_sid
		  LEFT JOIN initiative_region ir ON ir.initiative_sid = mi.initiative_sid AND ir.app_sid = mi.app_sid
		  LEFT JOIN initiative_tag it ON it.initiative_sid = mi.initiative_sid AND it.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu ON iu.initiative_sid = mi.initiative_sid AND iu.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu2 ON iu2.initiative_sid = mi.initiative_sid AND iu2.app_sid = mi.app_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
			   (in_text_filter IS NULL OR LOWER(i.name) LIKE '%'||LOWER(in_text_filter)||'%') AND
		       (in_region_sid IS NULL OR in_region_sid = 0 OR ir.region_sid = in_region_sid) AND
			   (in_flow_state_id IS NULL OR in_flow_state_id = 0 OR mi.flow_state_id = in_flow_state_id) AND
			   (in_project_sid IS NULL OR in_project_sid = 0 OR i.project_sid = in_project_sid) AND
			   (in_rag_status_id IS NULL OR in_rag_status_id = 0 OR i.rag_status_id = in_rag_status_id) AND
			   (in_tag_id IS NULL OR in_tag_id = 0 OR it.tag_id = in_tag_id) AND
			   (in_usergroup1_id IS NULL OR in_usergroup1_id = 0 OR iu.initiative_user_group_id = in_usergroup1_id) AND
			   (in_user1_id IS NULL OR in_user1_id = 0 OR iu.user_sid = in_user1_id) AND
			   (in_usergroup2_id IS NULL OR in_usergroup2_id = 0 OR iu2.initiative_user_group_id = in_usergroup2_id) AND
			   (in_user2_id IS NULL OR in_user2_id = 0 OR iu2.user_sid = in_user2_id);
END;

PROCEDURE PrepTeamroomExportViewFilter(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_text_filter			IN  VARCHAR2,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the teamroom with sid '||in_teamroom_sid);
	END IF;	

	-- uses v$my_intiatives so no need for further security checks
	DELETE FROM temp_initiative_sids;

	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT DISTINCT mi.initiative_sid
		  FROM v$my_initiatives mi
		  JOIN teamroom_initiative ti ON mi.initiative_sid = ti.initiative_sid AND mi.app_sid = ti.app_sid
		  LEFT JOIN initiative i ON i.initiative_sid = mi.initiative_sid AND i.app_sid = mi.app_sid
		  LEFT JOIN initiative_region ir ON ir.initiative_sid = mi.initiative_sid AND ir.app_sid = mi.app_sid
		  LEFT JOIN initiative_tag it ON it.initiative_sid = mi.initiative_sid AND it.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu ON iu.initiative_sid = mi.initiative_sid AND iu.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu2 ON iu2.initiative_sid = mi.initiative_sid AND iu2.app_sid = mi.app_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
			   ti.teamroom_sid = in_teamroom_sid AND
			   (in_text_filter IS NULL OR LOWER(i.name) like '%'||LOWER(in_text_filter)||'%') AND
		       (in_region_sid IS NULL OR in_region_sid = 0 OR ir.region_sid = in_region_sid) AND
			   (in_flow_state_id IS NULL OR in_flow_state_id = 0 OR mi.flow_state_id = in_flow_state_id) AND
			   (in_project_sid IS NULL OR in_project_sid = 0 OR i.project_sid = in_project_sid) AND
			   (in_rag_status_id IS NULL OR in_rag_status_id = 0 OR i.rag_status_id = in_rag_status_id) AND
			   (in_tag_id IS NULL OR in_tag_id = 0 OR it.tag_id = in_tag_id) AND
			   (in_usergroup1_id IS NULL OR in_usergroup1_id = 0 OR iu.initiative_user_group_id = in_usergroup1_id) AND
			   (in_user1_id IS NULL OR in_user1_id = 0 OR iu.user_sid = in_user1_id) AND
			   (in_usergroup2_id IS NULL OR in_usergroup2_id = 0 OR iu2.initiative_user_group_id = in_usergroup2_id) AND
			   (in_user2_id IS NULL OR in_user2_id = 0 OR iu2.user_sid = in_user2_id);
END;

PROCEDURE PrepPropertyExportViewFilter(
	in_property_sid			IN  security_pkg.T_SID_ID,
	in_text_filter			IN  VARCHAR2,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_property_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_property_sid);
	END IF;	

	DELETE FROM temp_initiative_sids;

	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT DISTINCT mi.initiative_sid
		  FROM v$my_initiatives mi
		  LEFT JOIN initiative i ON i.initiative_sid = mi.initiative_sid AND i.app_sid = mi.app_sid
		  LEFT JOIN initiative_region ir ON ir.initiative_sid = mi.initiative_sid AND ir.app_sid = mi.app_sid
		  LEFT JOIN initiative_tag it ON it.initiative_sid = mi.initiative_sid AND it.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu ON iu.initiative_sid = mi.initiative_sid AND iu.app_sid = mi.app_sid
		  LEFT JOIN initiative_user iu2 ON iu2.initiative_sid = mi.initiative_sid AND iu2.app_sid = mi.app_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
			   ir.region_sid IN (
					SELECT region_sid
					  FROM region
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						START WITH region_sid = in_property_sid
						CONNECT BY PRIOR region_sid = parent_sid
			   ) AND
			   (in_text_filter IS NULL OR LOWER(i.name) like '%'||LOWER(in_text_filter)||'%') AND
		       (in_region_sid IS NULL OR in_region_sid = 0 OR ir.region_sid = in_region_sid) AND
			   (in_flow_state_id IS NULL OR in_flow_state_id = 0 OR mi.flow_state_id = in_flow_state_id) AND
			   (in_project_sid IS NULL OR in_project_sid = 0 OR i.project_sid = in_project_sid) AND
			   (in_rag_status_id IS NULL OR in_rag_status_id = 0 OR i.rag_status_id = in_rag_status_id) AND
			   (in_tag_id IS NULL OR in_tag_id = 0 OR it.tag_id = in_tag_id) AND
			   (in_usergroup1_id IS NULL OR in_usergroup1_id = 0 OR iu.initiative_user_group_id = in_usergroup1_id) AND
			   (in_user1_id IS NULL OR in_user1_id = 0 OR iu.user_sid = in_user1_id) AND
			   (in_usergroup2_id IS NULL OR in_usergroup2_id = 0 OR iu2.initiative_user_group_id = in_usergroup2_id) AND
			   (in_user2_id IS NULL OR in_user2_id = 0 OR iu2.user_sid = in_user2_id);
END;

PROCEDURE GetInitiativeDetails(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_cur FOR
		SELECT tmp.initiative_sid, i.project_sid, i.parent_sid, i.flow_sid, i.flow_item_id, i.name,
			i.project_start_dtm, i.project_end_dtm, i.running_start_dtm, i.running_end_dtm,
			i.fields_xml, i.internal_ref, i.period_duration, i.created_by_sid, i.created_dtm, i.is_ramped, i.saving_type_id,
			f.current_state_id, s.label state_label, s.lookup_key state_lookup, s.attributes_xml state_attributes_xml,
			s.is_deleted state_is_deleted, s.state_colour, s.is_final state_is_final
		  FROM initiative i, flow_item f, flow_state s, TABLE(v_initiative_sids) tmp
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.initiative_sid = tmp.initiative_sid
		   AND f.flow_item_id = i.flow_item_id
		   AND s.flow_state_id = f.current_state_id
		   	ORDER BY tmp.initiative_sid;
END;

PROCEDURE GetInitiativeRegions(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_cur FOR
		SELECT tmp.initiative_sid, ir.region_sid, r.description, r.region_ref, r.lookup_key
		  FROM initiative_region ir, v$region r, TABLE(v_initiative_sids) tmp
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ir.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ir.initiative_sid = tmp.initiative_sid
		   AND r.region_sid = ir.region_sid
		   	ORDER BY tmp.initiative_sid;
END;

PROCEDURE GetInitiativeTags(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_cur FOR
		SELECT tmp.initiative_sid, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag tag_value
		  FROM initiative_tag it, v$tag t, tag_group_member tgm, v$tag_group tg, TABLE(v_initiative_sids) tmp
		 WHERE it.initiative_sid = tmp.initiative_sid
		   AND t.tag_id = it.tag_id
		   AND tgm.tag_id = t.tag_id
		   AND tg.tag_group_id = tgm.tag_group_id
		   	ORDER BY tmp.initiative_sid;
END;

PROCEDURE GetInitiativeUsers(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	-- XXX: WE NEED TO SEE THE FULL LIST OF ASSOCIATED USERS *REGARDLESS* OF THE STATE THE INITIATIVE IS *CURRENTLY* IN
	OPEN out_cur FOR
		SELECT i.initiative_sid, i.flow_sid, u.csr_user_sid user_sid, u.user_name, u.full_name, u.email, iu.initiative_user_group_id,
			MAX(NVL(igfs.is_editable, 0)) is_editable
		  FROM initiative i
		  JOIN TABLE(v_initiative_sids) tmp ON i.initiative_sid = tmp.initiative_sid
		  JOIN initiative_user iu ON i.initiative_sid = iu.initiative_sid AND i.app_sid = iu.app_sid
		  JOIN csr_user u ON iu.user_sid = u.csr_user_sid AND iu.app_sid = u.app_sid
		  LEFT JOIN initiative_group_flow_state igfs 
		    ON iu.initiative_user_group_id = igfs.initiative_user_group_id
		   AND iu.app_sid = igfs.app_sid
		  --JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid AND fi.current_state_id = igfs.flow_state_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY i.initiative_sid, i.flow_sid, u.csr_user_sid, u.user_name, u.full_name, u.email, iu.initiative_user_group_id
			 ORDER BY i.initiative_sid;
END;

-- XXX: How does this compare to initiative_metric_pkg.getallmetrics?
PROCEDURE GetInitiativeMetrics(
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_metrics FOR
		SELECT tmp.initiative_sid, p.project_sid, p.pos, p.update_per_period, p.default_value, p.input_dp, p.flow_sid, p.info_text,
			m.initiative_metric_id, m.measure_sid, m.is_saving, m.per_period_duration, m.one_off_period, m.is_during, m.is_running, m.is_rampable, m.label,
			val.entry_measure_conversion_id, val.entry_val, val.val,
			g.pos_group, g.is_group_mandatory, g.label group_label, g.info_text group_info_text,
			mfs.mandatory is_mandatory,
			DECODE (val.initiative_metric_id, NULL, 0, 1) measured_checked
		  FROM project_initiative_metric p, initiative_metric m, initiative_metric_val val, initiative_metric_group g,
		  		project_init_metric_flow_state mfs, initiative init, flow_item fl, TABLE(v_initiative_sids) tmp
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.initiative_metric_id = p.initiative_metric_id
		   AND val.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND val.initiative_metric_id = m.initiative_metric_id
		   AND val.initiative_sid = tmp.initiative_sid
		   AND g.project_sid = p.project_sid
		   AND g.pos_group = p.pos_group
		   AND mfs.project_sid = p.project_sid
		   AND mfs.initiative_metric_id = m.initiative_metric_id
		   AND mfs.flow_state_id = fl.current_state_id
		   AND mfs.visible = 1
		   AND init.initiative_sid = tmp.initiative_sid
		   AND init.project_sid = p.project_sid
		   AND fl.flow_item_id = init.flow_item_id
		   	ORDER BY tmp.initiative_sid;

	OPEN out_uom FOR
		SELECT DISTINCT tmp.initiative_sid, m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM initiative_metric_val val, csr.measure m, csr.measure_conversion mc, TABLE(v_initiative_sids) tmp
		 WHERE val.initiative_sid = tmp.initiative_sid
		   AND m.measure_sid = val.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid
		   	ORDER BY tmp.initiative_sid;

	OPEN out_assoc FOR
		SELECT tmp.initiative_sid, proposed_metric_id, measured_metric_id
		  FROM initiative i, initiative_metric_assoc a, TABLE(v_initiative_sids) tmp
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.initiative_sid = tmp.initiative_sid
		   AND a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.project_sid = i.project_sid
		   	ORDER BY tmp.initiative_sid;
END;

PROCEDURE GetInitiativeTeam(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_cur FOR
		SELECT tmp.initiative_sid, name, email
		  FROM initiative_project_team ipt, TABLE(v_initiative_sids) tmp
		 WHERE ipt.initiative_sid = tmp.initiative_sid
		 ORDER BY tmp.initiative_sid, ipt.name;
END;

PROCEDURE GetInitiativeSponsors(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_cur FOR
		SELECT tmp.initiative_sid, name, email
		  FROM initiative_sponsor isp, TABLE(v_initiative_sids) tmp
		 WHERE isp.initiative_sid = tmp.initiative_sid
		 	ORDER BY tmp.initiative_sid, isp.name;
END;

PROCEDURE GetDataForExport (
	out_data				OUT	security_pkg.T_OUTPUT_CUR,
	out_initiatives			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_users				OUT	security_pkg.T_OUTPUT_CUR,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uoms				OUT	security_pkg.T_OUTPUT_CUR,
	out_assocs				OUT	security_pkg.T_OUTPUT_CUR,
	out_teams				OUT	security_pkg.T_OUTPUT_CUR,
	out_sponsors			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_initiative_sids		T_INITIATIVE_SID_DATA_TABLE;
BEGIN
	SELECT T_INITIATIVE_SID_DATA_ROW(initiative_sid)
	  BULK COLLECT INTO v_initiative_sids
	  FROM temp_initiative_sids;

	OPEN out_data FOR
		SELECT
			init.lvl, MAX(init.lvl) OVER () max_lvl,
			init.initiative_sid, init.project_sid, init.initiative_name, init.initiative_reference,
			init.project_start_dtm, init.project_end_dtm, init.running_start_dtm, init.running_end_dtm,
			init.is_ramped, init.period_duration, init.created_dtm,
			init.region_sid, init.region_desc, init.region_ref,
			init.current_state_id, init.current_state_name,
		    static.initiative_metric_id,
		    static.label metric_name,
		    static.val metric_val,
		    static.entry_val metric_entry_val,
		    static.measure_sid metric_measure_sid,
		    static.entry_measure_conversion_id metric_conversion_id
	  	 FROM (
			SELECT ROWNUM rn, LEVEL lvl,
				i.initiative_sid, i.project_sid, i.name initiative_name, i.internal_ref initiative_reference,
				i.project_start_dtm, i.project_end_dtm, i.running_start_dtm, i.running_end_dtm,
				i.is_ramped, i.period_duration, i.created_dtm,
	        	rgn.region_sid, rgn.description region_desc, rgn.lookup_key region_ref,
	        	fli.current_state_id, fls.label current_state_name
		      FROM initiative i, initiative_region tr, v$region rgn, flow_item fli, flow_state fls
		     WHERE tr.initiative_sid(+) = i.initiative_sid
		       AND rgn.region_sid(+) = tr.region_sid
		       AND fli.flow_item_id = i.flow_item_id
		       AND fls.flow_state_id = fli.current_state_id
		       	START WITH i.parent_sid IS NULL
            	CONNECT BY PRIOR i.initiative_sid = i.parent_sid
            		ORDER SIBLINGS BY i.initiative_sid, rgn.region_sid
			) init, (
			    SELECT i.initiative_sid, im.initiative_metric_id, im.label,
			    	val.measure_sid, val.val, val.entry_val, val.entry_measure_conversion_id
		          FROM initiative i, initiative_metric im, project_initiative_metric pim, initiative_metric_val val
		         WHERE im.initiative_metric_id = pim.initiative_metric_id
		           AND pim.project_sid = i.project_sid
		           AND pim.update_per_period = 0
				   AND val.initiative_metric_id = im.initiative_metric_id
				   AND i.initiative_sid = val.initiative_sid
			) static, (
				SELECT DISTINCT i.initiative_sid
				  FROM initiative i, TABLE(v_initiative_sids) tmp
				 	START WITH i.initiative_sid = tmp.initiative_sid
				 	CONNECT BY PRIOR i.parent_sid = i.initiative_sid
			) filter
			WHERE init.initiative_sid = static.initiative_sid
			  AND init.initiative_sid = filter.initiative_sid
			ORDER BY init.rn;

	GetInitiativeDetails(out_initiatives);
	GetInitiativeRegions(out_regions);
	GetInitiativeTags(out_tags);
	GetInitiativeUsers(out_users);
	GetInitiativeMetrics(out_metrics, out_uoms, out_assocs);
	GetInitiativeTeam(out_teams);
	GetInitiativeSponsors(out_sponsors);
END;

END initiative_export_pkg;
/
