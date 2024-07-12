CREATE OR REPLACE PACKAGE CSR.target_dashboard_pkg AS

-- Securable object callbacks

/**
 * CreateObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_class_id				The class id of the object
 * @param in_name					The name
 * @param in_parent_sid_id			The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_name				The name
 */
PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		The sid of the new parent object
 */
PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

/**
 * Create a new Dashboard
 *
 * @param in_act_id					Access token
 * @param in_parent_sid				The sid of the parent object
 * @param in_name					The name
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_period_set_id			The period set
 * @param in_period_interval_id		The period interval (m|q|h|y)
 * @param in_use_root_region_sid	Use the users root region sid to dynamically populate the region range
 * @param out_dashboard_sid_id		The SID of the created object
 */
PROCEDURE CreateDashboard(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	target_dashboard.name%TYPE,
	in_start_dtm					IN	target_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	target_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	target_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	target_dashboard.period_interval_id%TYPE,
	in_use_root_region_sid			IN	target_dashboard.use_root_region_sid%TYPE,
	out_dashboard_sid_id			OUT security_pkg.T_SID_ID
);

/**
 * Update a Dashboard
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard to update	 
 * @param in_name					The name
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_period_set_id			The period set
 * @param in_period_interval_id		The period interval (m|q|h|y)
 * @param in_use_root_region_sid	Use the users root region sid to dynamically populate the region range
 */
PROCEDURE AmendDashboard(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	target_dashboard.name%TYPE,
	in_start_dtm					IN	target_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	target_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	target_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	target_dashboard.period_interval_id%TYPE,
	in_use_root_region_sid			IN	target_dashboard.use_root_region_sid%TYPE
);

/**
 * Remove all inds/regions from a dashboard
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 */
PROCEDURE ClearMembers(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID
);

/**
 * Get the indicators belonging to the dashboard
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param out_cur					The indicators
 */
PROCEDURE GetIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Get the regions belonging to the dashboard
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param out_cur					The indicators
 */
PROCEDURE GetRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Set association between and indicator and the relevant target indicator
 * 
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param in_ind_sid				The sid of the indicator
 * @param in_target_sid				The target indicator
 */
PROCEDURE AddIndTargetSid(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_target_sid					IN	security_pkg.T_SID_ID
);

/**
 * Add a region to the dashboard
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param in_ind_sid				The sid of the region
 */ 
PROCEDURE AddRegion(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID
);

/**
 * Get the target indicator
 * 
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param in_ind_sid				The sid of the indicator 
 * @param out_target_ind_sid		The sid of the target indicator
 */
PROCEDURE GetTargetSid(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_target_ind_sid				OUT security_pkg.T_SID_ID
);

/**
 * GetTargetSids
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param out_cur					The target indicators
 */
PROCEDURE GetTargetSids(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Get target dashboard details
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param out_cur					The dashboard details
 */
PROCEDURE GetDashboard(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,	 
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Get target values for the given dashboard / indicator
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param in_ind_sid				The indicator
 * @param out_cur					The target values
 */
PROCEDURE GetDashboardTargetsForInd(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid	 					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * List target dashboards contained in a folder
 *
 * @param in_act_id					Access token
 * @param in_parent_sid				The sid of the folder containing the dashboards
 * @param in_order_by				Sort order
 * @param in_start_row				First row to return
 * @param in_page_size				Number of rows to return
 * @param out_total_rows			Total number of rows that exist
 * @param out_cur					The rowset
 */
PROCEDURE GetDashboardList(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_parent_sid					IN 	security_pkg.T_SID_ID,	 
	in_order_by						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Set a target value for an indicator on a dashboard
 *
 * @param in_act_id					Access token
 * @param in_dashboard_sid			The dashboard
 * @param in_ind_sid				The indicator
 * @param in_region_sid				The region
 * @param in_val_number				The target value
 */
PROCEDURE SetDashboardTarget(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_dashboard_sid				IN 	security_pkg.T_SID_ID,
	in_ind_sid	 					IN	security_pkg.T_SID_ID,
	in_region_sid	 				IN	security_pkg.T_SID_ID,
	in_val_number	 				IN	target_dashboard_value.val_number%TYPE
);

END target_dashboard_pkg;
/
