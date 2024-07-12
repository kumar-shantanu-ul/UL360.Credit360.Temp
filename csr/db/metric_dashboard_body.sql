CREATE OR REPLACE PACKAGE BODY CSR.metric_dashboard_pkg AS

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
	DELETE FROM metric_dashboard_plugin
	 WHERE metric_dashboard_sid = in_sid_id;
	
	DELETE FROM metric_dashboard_ind
	 WHERE metric_dashboard_sid = in_sid_id;
	
	DELETE FROM metric_dashboard
	 WHERE metric_dashboard_sid = in_sid_id;	
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
	
	SELECT DECODE(COUNT(m.metric_dashboard_sid), 0, 0, 1) INTO v_check
	  FROM metric_dashboard m
	  JOIN security.securable_object s 
			 ON s.sid_id = m.metric_dashboard_sid
			AND s.parent_sid_id = v_parent_sid
	 WHERE m.app_sid = v_app_sid;
	
	RETURN v_check;
	
EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		RETURN 0;
END;

PROCEDURE CreateDashboard(
	in_name							IN	metric_dashboard.name%TYPE,
	in_start_dtm					IN	metric_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	metric_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	metric_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	metric_dashboard.period_interval_id%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid	NUMBER(10);
BEGIN
	v_parent_sid := securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Dashboards');

	securableobject_pkg.CreateSO(security_pkg.getACT,
		v_parent_sid, 
		class_pkg.getClassID('CSRMetricDashboard'),
		REPLACE(in_name,'/','\'), --'
		out_dashboard_sid);	
		
	INSERT INTO metric_dashboard (metric_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id)
	VALUES (out_dashboard_sid, in_name, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id);
END;


PROCEDURE SaveDashboard(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	metric_dashboard.name%TYPE,
	in_start_dtm					IN	metric_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	metric_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	metric_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	metric_dashboard.period_interval_id%TYPE,
	in_lookup_key					IN	metric_dashboard.lookup_key%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	IF in_dashboard_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving dashboard sid '||in_dashboard_sid);
		END IF;	

		UPDATE metric_dashboard
		   SET name = in_name,
			   start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   period_set_id = in_period_set_id,
			   period_interval_id = in_period_interval_id,
			   lookup_key = in_lookup_key
		 WHERE metric_dashboard_sid = in_dashboard_sid;

		out_dashboard_sid := in_dashboard_sid;
	ELSE
		CreateDashboard(in_name, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id, out_dashboard_sid);

		UPDATE metric_dashboard
		   SET lookup_key = in_lookup_key
		 WHERE metric_dashboard_sid = out_dashboard_sid;
	END IF;
END;

PROCEDURE TrashDashboard(
	in_dashboard_sid				IN security_pkg.T_SID_ID
)
AS
	v_name					METRIC_DASHBOARD.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trashing dashboard sid '||in_dashboard_sid);
	END IF;	
	
	SELECT name INTO v_name
	  FROM metric_dashboard
	 WHERE metric_dashboard_sid = in_dashboard_sid;

	trash_pkg.TrashObject(security_pkg.GetAct, in_dashboard_sid,
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash'),
		v_name);

	UPDATE metric_dashboard
	   SET lookup_key = NULL
	 WHERE metric_dashboard_sid = in_dashboard_sid;
END;

PROCEDURE SaveDashboardInd(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_ind_sid						IN security_pkg.T_SID_ID,
	in_pos							IN metric_dashboard_ind.pos%TYPE, 
	in_block_title					IN metric_dashboard_ind.block_title%TYPE, 
	in_block_css_class				IN metric_dashboard_ind.block_css_class%TYPE, 
	in_floor_area_ind_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;	

	BEGIN
		INSERT INTO metric_dashboard_ind
			   (metric_dashboard_sid, ind_sid, pos,
				block_title, block_css_class,
				inten_view_floor_area_ind_sid)
		VALUES (in_dashboard_sid, in_ind_sid, in_pos,
				in_block_title, in_block_css_class,
				in_floor_area_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE metric_dashboard_ind
				SET pos = in_pos,
					block_title = in_block_title,
					block_css_class = in_block_css_class,
					inten_view_floor_area_ind_sid = in_floor_area_ind_sid
			  WHERE metric_dashboard_sid = in_dashboard_sid
			    AND ind_sid = in_ind_sid;
	END;
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

	DELETE FROM metric_dashboard_ind
		  WHERE metric_dashboard_sid = in_dashboard_sid
			AND ind_sid = in_ind_sid;
END;

PROCEDURE UNSEC_GetDashboards(
	in_dashboard_sids				IN	security.T_SID_TABLE, 
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT metric_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
			   lookup_key
		  FROM metric_dashboard
		 WHERE metric_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids));	
		 
	OPEN out_cur_inds FOR
		SELECT metric_dashboard_sid, ind_sid, pos, block_title, block_css_class, inten_view_scenario_run_sid, inten_view_floor_area_ind_sid, absol_view_scenario_run_sid		
		  FROM metric_dashboard_ind
		 WHERE metric_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids))	
		 ORDER BY pos;
		 
	OPEN out_cur_plugins FOR
		SELECT mdp.metric_dashboard_sid, p.plugin_id, p.plugin_type_id, p.js_include, p.js_class, p.cs_class 		
		  FROM metric_dashboard_plugin mdp
		  JOIN plugin p on mdp.plugin_id = p.plugin_id
		  JOIN plugin_type pt on pt.plugin_type_id = p.plugin_type_id
		 WHERE mdp.metric_dashboard_sid IN (SELECT column_value FROM TABLE(in_dashboard_sids))
		 ORDER BY p.plugin_id;
END;

PROCEDURE GetDashboard(
	in_dashboard_sid				IN  metric_dashboard.metric_dashboard_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR
)
AS
	v_dashboard_sids	security.T_SID_TABLE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading dashboard sid '||in_dashboard_sid);
	END IF;	

	v_dashboard_sids := security.T_SID_TABLE(in_dashboard_sid);
	
	UNSEC_GetDashboards(v_dashboard_sids, out_cur, out_cur_inds, out_cur_plugins);
END;

PROCEDURE GetDashboardByLookupKey(
	in_lookup_key		IN  metric_dashboard.lookup_key%TYPE, 
	out_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_inds		OUT security_pkg.T_OUTPUT_CUR,
	out_cur_plugins		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dashboard_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT metric_dashboard_sid
	  INTO v_dashboard_sid
	  FROM metric_dashboard
	 WHERE lookup_key = in_lookup_key;
	
	GetDashboard(v_dashboard_sid, out_cur, out_cur_inds, out_cur_plugins);	
END;

PROCEDURE GetDashboards(
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR
)
AS
	v_dashboards_sid	security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Dashboards');
	v_dashboard_sids	security.T_SID_TABLE;
BEGIN
	SELECT metric_dashboard_sid
	 BULK COLLECT INTO v_dashboard_sids
	 FROM metric_dashboard md
	 JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_dashboards_sid, security_pkg.PERMISSION_READ)) so
	   ON md.metric_dashboard_sid = so.sid_id;

	UNSEC_GetDashboards(v_dashboard_sids, out_cur, out_cur_inds, out_cur_plugins);	
END;

END;
/
