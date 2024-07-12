CREATE OR REPLACE PACKAGE BODY CSR.Dashboard_Pkg AS
-- Securable object callbacks

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
) AS
BEGIN	
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		UPDATE DASHBOARD SET NAME = in_new_name WHERE Dashboard_sid = in_sid_id;
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN													  
	DELETE FROM DASHBOARD_ITEM WHERE Dashboard_sid = in_sid_id;
	DELETE FROM DASHBOARD WHERE Dashboard_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;


/**
 * Create a new Dashboard
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param	in_note					Note
 * @param	out_dashboard_sid		The SID of the created object
 *
 */
PROCEDURE CreateDashboard(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_parent_sid_id			IN 	security_pkg.T_SID_ID, 
	in_name						IN 	DASHBOARD.NAME%TYPE,
	in_note						IN 	DASHBOARD.NOTE%TYPE,
	out_dashboard_sid			OUT DASHBOARD.Dashboard_sid%TYPE
)
AS
BEGIN	
	SecurableObject_Pkg.CreateSO(in_act_id, in_parent_sid_id, 
		class_pkg.getClassID('CSRDashboard'), REPLACE(in_name,'/','\'), out_dashboard_sid);
	INSERT INTO DASHBOARD 
		(dashboard_sid, name, NOTE)
	VALUES 
		(out_Dashboard_sid, in_name, in_note);
END;


PROCEDURE AddDashboardItem(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_dashboard_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_period				IN	DASHBOARD_ITEM.PERIOD%TYPE,
	in_comparison_type		IN	DASHBOARD_ITEM.comparison_type%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_dataview_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	DASHBOARD_ITEM.name%TYPE,
	in_pos					IN	DASHBOARD_ITEM.pos%TYPE,
	out_dashboard_item_id	OUT	DASHBOARD_ITEM.dashboard_item_id%TYPE
)
AS
	v_pos	DASHBOARD_ITEM.pos%TYPE;
BEGIN
	-- do we have add_contents permission
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF in_pos IS NULL THEN
		SELECT NVL(MAX(pos),0)+1 INTO v_pos
			FROM DASHBOARD_ITEM WHERE parent_sid = in_parent_sid;
	ELSE
		v_pos := in_pos;
	END IF;
	
	INSERT INTO DASHBOARD_ITEM
		(dashboard_item_id, dashboard_sid, parent_sid, PERIOD, 
		 comparison_type, ind_sid, region_sid, dataview_sid, name, pos)
	VALUES
		(dashboard_item_id_seq.NEXTVAL, in_dashboard_sid, in_parent_sid, in_period,
		 in_comparison_type, in_ind_sid, in_region_sid, in_dataview_sid, in_name, v_pos)
	RETURNING dashboard_item_id INTO out_dashboard_item_id; 
END;


PROCEDURE GetDashboardItem(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_dashboard_item_id	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dashboard_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT DASHBOARD_SID INTO v_dashboard_sid
	  FROM DASHBOARD_ITEM
	 WHERE DASHBOARD_ITEM_ID = in_dashboard_item_id;

	-- do we have list_contents permission
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_dashboard_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT DI.PARENT_SID, securableobject_pkg.GetName(in_act_id, di.parent_sid) parent_name, 
			DASHBOARD_ITEM_ID, PERIOD, dashboard_sid,
			DI.COMPARISON_TYPE,	CT.DESCRIPTION COMPARISON_TYPE_DESCRIPTION, DI.IND_SID, REGION_SID, DI.NAME, 
			I.START_MONTH, NVL(I.FORMAT_MASK, M.FORMAT_MASK) FORMAT_MASK, 
			M.DESCRIPTION MEASURE_DESCRIPTION,
			TARGET_DIRECTION, DATAVIEW_SID
		  FROM DASHBOARD_ITEM DI, DASHBOARD_ITEM_COMPARISON_TYPE CT, IND I, MEASURE M 
		 WHERE dashboard_item_id = in_dashboard_item_id
		   AND DI.COMPARISON_TYPE = CT.COMPARISON_TYPE
		   AND I.IND_SID = DI.IND_SID
		   AND I.MEASURE_SID = M.MEASURE_SID;
END;


PROCEDURE GetDashboardItems(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- do we have add_contents permission
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_dashboard_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT di.parent_sid, so.name parent_name, dashboard_item_id, period, 
			   di.comparison_type, ct.description comparison_type_description, di.ind_sid, region_sid, di.name, 
			   i.start_month, NVL(i.format_mask, m.format_mask) format_mask, 
			   m.description measure_description, target_direction, dataview_sid
		  FROM TABLE(securableobject_pkg.GetChildrenAsTable(in_act_id, in_dashboard_sid)) so,
		       dashboard_item di, dashboard_item_comparison_type ct, ind i, measure m 
		 WHERE dashboard_sid = in_dashboard_sid
		   AND di.comparison_type = ct.comparison_type
		   AND i.ind_sid = di.ind_sid
		   AND i.measure_sid = m.measure_sid
		   AND so.sid_id = di.parent_sid
		 ORDER BY parent_sid, di.pos;
END;


PROCEDURE GetDashboardReport(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	OPEN out_cur FOR
		SELECT di.parent_sid, securableobject_pkg.getname(in_act_id, di.parent_sid) parent_name, 
			   dashboard_item_id, period, dashboard_sid,
			   di.comparison_type,	ct.description comparison_type_description, di.ind_sid, region_sid, di.name, 
			   i.start_month, NVL(i.format_mask, m.format_mask) format_mask, 
			   m.description measure_description,
			   target_direction, dv.dataview_sid,
		       dv.name dataview_name, dv.start_dtm, dv.end_dtm, dv.group_by, 
		       dv.period_set_id, dv.period_interval_id, dv.chart_config_xml
		  FROM dashboard_item di, dashboard_item_comparison_type ct, ind i, measure m, dataview dv
		 WHERE di.parent_sid = in_parent_sid
		   AND di.dataview_sid = dv.dataview_sid
		   AND di.comparison_type = ct.comparison_type
		   AND i.ind_sid = di.ind_sid
		   AND i.measure_sid = m.measure_sid
		 ORDER BY di.pos;
END;

END;
/
