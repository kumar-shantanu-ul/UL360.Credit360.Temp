CREATE OR REPLACE PACKAGE BODY CSR.benchmarking_dashboard_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM benchmark_dashboard_plugin
	 WHERE benchmark_dashboard_sid = in_sid_id;

	DELETE FROM benchmark_dashboard_ind
	 WHERE benchmark_dashboard_sid = in_sid_id;

	DELETE FROM benchmark_dashboard_char
	 WHERE benchmark_dashboard_sid = in_sid_id;

	DELETE FROM benchmark_dashboard
	 WHERE benchmark_dashboard_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

FUNCTION IsSetup
RETURN NUMBER
AS
v_parent_sid	NUMBER(10);
v_app_sid		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
v_check			NUMBER(1);
BEGIN
	v_parent_sid := securableobject_pkg.getSIDFromPath(security_pkg.getACT, v_app_sid, 'Dashboards');
	
	SELECT DECODE(COUNT(b.benchmark_dashboard_sid), 0, 0, 1) INTO v_check
	  FROM benchmark_dashboard b
	  JOIN security.securable_object s 
			 ON s.sid_id = b.benchmark_dashboard_sid
			AND s.parent_sid_id = v_parent_sid
	 WHERE b.app_sid = v_app_sid;
	
	RETURN v_check;
	
EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		RETURN 0;
END;

PROCEDURE CreateDashboard(
	in_name							IN	benchmark_dashboard.name%TYPE,
	in_start_dtm					IN	benchmark_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	benchmark_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	benchmark_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	benchmark_dashboard.period_interval_id%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid	NUMBER(10);
BEGIN
	v_parent_sid := securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Dashboards');

	securableobject_pkg.CreateSO(security_pkg.getACT,
		v_parent_sid, 
		class_pkg.getClassID('CSRBenchmarkingDashboard'),
		REPLACE(in_name,'/','\'), --'
		out_dashboard_sid);	
		
	INSERT INTO benchmark_dashboard (benchmark_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id)
	VALUES (out_dashboard_sid, in_name, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id);
END;

PROCEDURE SaveDashboard(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	benchmark_dashboard.name%TYPE,
	in_start_dtm					IN	benchmark_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	benchmark_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	benchmark_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	benchmark_dashboard.period_interval_id%TYPE,
	in_lookup_key					IN	benchmark_dashboard.lookup_key%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	IF in_dashboard_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving dashboard sid '||in_dashboard_sid);
		END IF;	

		UPDATE benchmark_dashboard
		   SET name = in_name,
			   start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   period_set_id = in_period_set_id,
			   period_interval_id = in_period_interval_id,
			   lookup_key = in_lookup_key
		 WHERE benchmark_dashboard_sid = in_dashboard_sid;

		out_dashboard_sid := in_dashboard_sid;
	ELSE
		CreateDashboard(in_name, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id, out_dashboard_sid);

		UPDATE benchmark_dashboard
		   SET lookup_key = in_lookup_key
		 WHERE benchmark_dashboard_sid = out_dashboard_sid;
	END IF;
END;

PROCEDURE TrashDashboard(
	in_dashboard_sid				IN security_pkg.T_SID_ID
)
AS
	v_name					benchmark_dashboard.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trashing dashboard sid '||in_dashboard_sid);
	END IF;	
	
	SELECT name INTO v_name
	  FROM benchmark_dashboard
	 WHERE benchmark_dashboard_sid = in_dashboard_sid;

	trash_pkg.TrashObject(security_pkg.GetAct, in_dashboard_sid,
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash'),
		v_name);

	UPDATE benchmark_dashboard
	   SET lookup_key = NULL
	 WHERE benchmark_dashboard_sid = in_dashboard_sid;
END;

PROCEDURE SaveDashboardInd(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_ind_sid						IN security_pkg.T_SID_ID,
	in_pos							IN benchmark_dashboard_ind.pos%TYPE, 
	in_display_name					IN benchmark_dashboard_ind.display_name%TYPE, 
	in_floor_area_ind_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;	

	BEGIN
		INSERT INTO benchmark_dashboard_ind
			   (benchmark_dashboard_sid, ind_sid, pos,
				display_name,
				floor_area_ind_sid)
		VALUES (in_dashboard_sid, in_ind_sid, in_pos,
				in_display_name,
				in_floor_area_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE benchmark_dashboard_ind
				SET pos = in_pos,
					display_name = in_display_name,
					floor_area_ind_sid = in_floor_area_ind_sid
			  WHERE benchmark_dashboard_sid = in_dashboard_sid
			    AND ind_sid = in_ind_sid;
	END;
END;

PROCEDURE SaveDashboardChar(
	in_benchmark_dashboard_sid		 IN security_pkg.T_SID_ID,
	in_benchmark_dashboard_char_id	 IN benchmark_dashboard_char.benchmark_dashboard_char_id%TYPE,
	in_pos							 IN benchmark_dashboard_char.pos%TYPE,
	in_ind_sid						 IN security_pkg.T_SID_ID,
	in_tag_group_id					 IN security_pkg.T_SID_ID,
	out_benchmark_dashb_char_id		OUT benchmark_dashboard_char.benchmark_dashboard_char_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_benchmark_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_benchmark_dashboard_sid);
	END IF;

	IF in_benchmark_dashboard_char_id IS NULL THEN
		INSERT INTO benchmark_dashboard_char (benchmark_dashboard_sid, benchmark_dashboard_char_id, pos, ind_sid, tag_group_id)
		     VALUES (in_benchmark_dashboard_sid, csr.benchmark_dashb_char_id_seq.nextval, in_pos, in_ind_sid, in_tag_group_id)
          RETURNING benchmark_dashboard_char_id
               INTO out_benchmark_dashb_char_id;
	ELSE
		UPDATE benchmark_dashboard_char
		   SET pos = in_pos
		 WHERE benchmark_dashboard_char_id = in_benchmark_dashboard_char_id;

		out_benchmark_dashb_char_id := in_benchmark_dashboard_char_id;
	END IF;
END;

PROCEDURE DeleteDashboardInd(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_ind_sid						IN security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;	

	DELETE FROM benchmark_dashboard_ind
		  WHERE benchmark_dashboard_sid = in_dashboard_sid
			AND ind_sid = in_ind_sid;
END;

PROCEDURE DeleteDashboardChar(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_benchmark_dashboard_char_id	IN benchmark_dashboard_char.benchmark_dashboard_char_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;

	DELETE FROM benchmark_dashboard_char
		  WHERE benchmark_dashboard_sid = in_dashboard_sid AND benchmark_dashboard_char_id = in_benchmark_dashboard_char_id;
END;

PROCEDURE UNSEC_GetDashboards(
	in_dashboard_sids				IN	security.T_SID_TABLE,
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR,
	out_cur_characteristics			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT benchmark_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id, lookup_key
		  FROM benchmark_dashboard
		 WHERE benchmark_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids));

	OPEN out_cur_inds FOR
		SELECT bdi.benchmark_dashboard_sid, bdi.ind_sid, bdi.pos, bdi.display_name, bdi.scenario_run_sid, bdi.floor_area_ind_sid
		  FROM benchmark_dashboard_ind bdi
		  JOIN v$ind i ON bdi.app_sid = i.app_sid AND bdi.ind_sid = i.ind_sid
		 WHERE bdi.benchmark_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids))
		 ORDER BY bdi.pos;

	OPEN out_cur_plugins FOR
		SELECT bdp.benchmark_dashboard_sid, p.plugin_id, p.plugin_type_id, p.js_include, p.js_class, p.cs_class
		  FROM benchmark_dashboard_plugin bdp
		  JOIN plugin p on bdp.plugin_id = p.plugin_id
		  JOIN plugin_type pt on pt.plugin_type_id = p.plugin_type_id
		 WHERE bdp.benchmark_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids))
		 ORDER BY p.plugin_id;

	OPEN out_cur_characteristics FOR
		SELECT bdc.benchmark_dashboard_sid, bdc.benchmark_dashboard_char_id, bdc.ind_sid, bdc.tag_group_id,
		       NVL(i.description, tg.name) AS description, bdc.pos,
		       m.description AS measure_description, m.custom_field AS measure_custom_field, m.scale AS measure_scale, m.format_mask AS measure_format_mask
		  FROM csr.benchmark_dashboard_char bdc
		  LEFT JOIN csr.v$ind i ON bdc.app_sid =  i.app_sid AND bdc.ind_sid = i.ind_sid
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN csr.v$tag_group tg ON bdc.app_sid = tg.app_sid AND bdc.tag_group_id = tg.tag_group_id
		 WHERE bdc.benchmark_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids))
		   AND (i.ind_sid IS NOT NULL OR tg.tag_group_id IS NOT NULL)
		   -- exclude check-box, date, text and file upload metrics
		   AND (i.ind_sid IS NULL OR (m.custom_field IS NULL OR m.custom_field NOT IN ('x', '$', '|', '&')))
		 ORDER BY bdc.pos;
END;

PROCEDURE UNSEC_GetDashboardCharsTags(
	in_dashboard_sid				 IN security_pkg.T_SID_ID,
	out_cur_tags					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_tags FOR
		SELECT bdc.benchmark_dashboard_char_id, t.tag_id, t.tag AS tag_name
		  FROM csr.benchmark_dashboard_char bdc
		  JOIN csr.tag_group tg ON bdc.app_sid = tg.app_sid AND bdc.tag_group_id = tg.tag_group_id
		  JOIN csr.tag_group_member tgm ON tg.tag_group_id = tgm.tag_group_id
		  JOIN csr.v$tag t ON tgm.tag_id = t.tag_id
		 WHERE bdc.benchmark_dashboard_sid = in_dashboard_sid;
END;

PROCEDURE GetDashboard(
	in_dashboard_sid				IN  benchmark_dashboard.benchmark_dashboard_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR,
	out_cur_characteristics			OUT SYS_REFCURSOR,
	out_cur_characteristics_tags	OUT SYS_REFCURSOR
)
AS
	v_dashboard_sids	security.T_SID_TABLE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;	

	v_dashboard_sids := security.T_SID_TABLE(in_dashboard_sid);
	
	UNSEC_GetDashboards(v_dashboard_sids, out_cur, out_cur_inds, out_cur_plugins, out_cur_characteristics);
	UNSEC_GetDashboardCharsTags(in_dashboard_sid, out_cur_characteristics_tags);
END;
	
PROCEDURE GetDashboardByName(
	in_dashboard_name				IN  benchmark_dashboard.name%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR,
	out_cur_characteristics			OUT SYS_REFCURSOR,
	out_cur_characteristics_tags	OUT SYS_REFCURSOR
)
AS
	v_dashboard_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT benchmark_dashboard_sid
	  INTO v_dashboard_sid
	  FROM benchmark_dashboard
	 WHERE name = in_dashboard_name;
	
	GetDashboard(v_dashboard_sid, out_cur, out_cur_inds, out_cur_plugins, out_cur_characteristics, out_cur_characteristics_tags);	
END;

PROCEDURE GetDashboardByLookupKey(
	in_lookup_key				 	 IN benchmark_dashboard.lookup_key%TYPE, 
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_cur_inds					OUT security_pkg.T_OUTPUT_CUR,
	out_cur_plugins					OUT security_pkg.T_OUTPUT_CUR,
	out_cur_characteristics			OUT security_pkg.T_OUTPUT_CUR,
	out_cur_characteristics_tags	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dashboard_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT benchmark_dashboard_sid
	  INTO v_dashboard_sid
	  FROM benchmark_dashboard
	 WHERE lookup_key = in_lookup_key;
	
	GetDashboard(v_dashboard_sid, out_cur, out_cur_inds, out_cur_plugins, out_cur_characteristics, out_cur_characteristics_tags);	
END;

PROCEDURE GetDashboards(
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR,
	out_cur_characteristics			OUT SYS_REFCURSOR
)
AS
	v_dashboards_sid	security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Dashboards');
	v_dashboard_sids	security.T_SID_TABLE;
BEGIN
	SELECT benchmark_dashboard_sid
	 BULK COLLECT INTO v_dashboard_sids
	  FROM benchmark_dashboard bd
	  JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_dashboards_sid, security_pkg.PERMISSION_READ)) so
	    ON bd.benchmark_dashboard_sid = so.sid_id;

	UNSEC_GetDashboards(v_dashboard_sids, out_cur, out_cur_inds, out_cur_plugins, out_cur_characteristics);	
END;

END;
/
