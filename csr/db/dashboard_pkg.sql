CREATE OR REPLACE PACKAGE CSR.Dashboard_Pkg AS

COMP_THIS_V_PREVIOUS			CONSTANT	NUMBER(10) := 1;
COMP_THIS_V_SAME_LAST_YR		CONSTANT	NUMBER(10) := 2;
COMP_LAST_KNOWN_V_PREVIOUS		CONSTANT	NUMBER(10) := 3;
COMP_LAST_KNOWN_V_SAME_LAST_YR	CONSTANT	NUMBER(10) := 4;
COMP_YTD_V_LAST_YTD				CONSTANT	NUMBER(10) := 5;
COMP_LAST_YR_V_YR_BEFORE_LAST	CONSTANT	NUMBER(10) := 6;


-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

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
);

/**
 * AddDashboardItem
 * 
 * @param in_act_id					Access token
 * @param in_dashboard_sid			.
 * @param in_parent_sid				The sid of the parent object
 * @param in_period					.
 * @param in_comparison_type		.
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_dataview_sid			.
 * @param in_name					The name
 * @param in_pos					.
 * @param out_dashboard_item_id		.
 */
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
);

/**
 * GetDashboardItem
 * 
 * @param in_act_id					Access token
 * @param in_dashboard_item_id		.
 * @param out_cur					The rowset
 */
PROCEDURE GetDashboardItem(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_dashboard_item_id	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * GetDashboardItems
 * 
 * @param in_act_id				Access token
 * @param in_dashboard_sid		.
 * @param out_cur				The rowset
 */
PROCEDURE GetDashboardItems(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_dashboard_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * GetDashboardReport
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param out_cur			The rowset
 */
PROCEDURE GetDashboardReport(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);
END Dashboard_Pkg;
/
